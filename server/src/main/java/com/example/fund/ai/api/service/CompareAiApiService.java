package com.example.fund.ai.api.service;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;

import com.example.fund.api.dto.UserInfo;
import com.example.fund.api.service.UserApiService;
import com.example.fund.fund.dto.FundListResponseDTO;
import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundReturn;
import com.example.fund.fund.repository_fund.FundRepository;
import com.example.fund.fund.repository_fund.FundReturnRepository;
import com.fasterxml.jackson.core.json.JsonReadFeature;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CompareAiApiService {

  private final ChatClient chatClient;
  private final FundRepository fundRepository;
  private final FundReturnRepository fundReturnRepository;

  // userId로 투자성향 조회(1년 경과 시 null 처리 되는 메서드 보유)
  private final UserApiService userApiService;

  // 관대한 JSON 검증용
  private final ObjectMapper mapper = new ObjectMapper()
      .enable(JsonReadFeature.ALLOW_SINGLE_QUOTES.mappedFeature())
      .enable(JsonReadFeature.ALLOW_UNESCAPED_CONTROL_CHARS.mappedFeature())
      .enable(JsonReadFeature.ALLOW_TRAILING_COMMA.mappedFeature());

  /** 메인: fundIds와 userId를 받아 LLM JSON(새 스키마)을 그대로 반환 */
  public String compareByUserAndFundIdsReturnJson(Integer userId, List<String> fundIds) {
    if (fundIds == null || fundIds.size() < 2) {
      throw new IllegalArgumentException("비교할 펀드는 최소 2개 이상이어야 합니다.");
    }

    // 1) 사용자 투자성향 이름 조회 (1년 지나면 null)
    String typeName = null;
    if (userId != null) {
      UserInfo info = userApiService.getUserInfo(userId);
      typeName = info.getTypename(); // null이면 미설정
    }
    final String profileText = normalizeProfile(typeName); // 5종 + 미설정

    // 2) 펀드 요약 DTO 구성 (FundListResponseDTO)
    List<FundListResponseDTO> funds = new ArrayList<>();
    for (String id : fundIds) {
      Fund f = fundRepository.findById(id)
          .orElseThrow(() -> new IllegalArgumentException("Fund not found: " + id));
      FundReturn r = fundReturnRepository
          .findTopByFund_FundIdOrderByBaseDateDesc(id).orElse(null);

      funds.add(FundListResponseDTO.builder()
          .fundId(f.getFundId())
          .fundName(f.getFundName())
          .fundType(f.getFundType())
          .fundDivision(f.getFundDivision())
          .riskLevel(f.getRiskLevel())
          .managementCompany(f.getManagementCompany())
          .issueDate(f.getIssueDate())
          .return1m(r == null || r.getReturn1m() == null ? null : r.getReturn1m().doubleValue())
          .return3m(r == null || r.getReturn3m() == null ? null : r.getReturn3m().doubleValue())
          .return12m(r == null || r.getReturn12m() == null ? null : r.getReturn12m().doubleValue())
          .build());
    }

    // 3) 프롬프트 생성 & 호출
    String prompt = buildJsonPrompt(funds, profileText);
    String raw = callLlm(prompt);
    System.out.println(raw);

    // 4) LLM 출력 클린업 후 검증 -> 그대로 반환 (새 스키마)
    String pure = extractPureJson(raw);
    String ok = ensureJson(pure);
    if (ok != null) return ok;

    // 5) 정말 JSON이 아니면 "새 스키마" 기본값을 반환 (UI 안전)
    return """
    {
      "profileSummary": "분석 결과를 파싱하지 못했습니다. 다시 시도해 주세요.",
      "prosCons": {
        "A": { "pros": [], "cons": [] },
        "B": { "pros": [], "cons": [] }
      },
      "finalPick": { "pick": "tie", "reason": "충분한 정보가 없어 중립적으로 판단합니다." },
      "riskNote": "과거 수익률은 미래 성과를 보장하지 않습니다."
    }
    """;
  }

  // ====== 프롬프트 ======
  private String nv(Object o) { return o == null ? "-" : String.valueOf(o); }

  /** 사용자 프로필 이름 표준화: 안정형/안정추구형/위험중립형/적극투자형/공격투자형/미설정 */
  private String normalizeProfile(String typeName) {
    if (typeName == null || typeName.isBlank()) return "미설정";
    final String t = typeName.replaceAll("\\s", "");
    // 정확도 높은 순서대로 매칭
    if (t.contains("안정추구")) return "안정추구형";
    if (t.contains("안정"))    return "안정형";
    if (t.contains("중립"))    return "위험중립형";
    if (t.contains("적극"))    return "적극투자형";
    if (t.contains("공격"))    return "공격투자형";
    // 혹시 이미 정확 표기면 그대로
    switch (typeName) {
      case "안정형", "안정추구형", "위험중립형", "적극투자형", "공격투자형":
        return typeName;
    }
    return "미설정";
  }

  /** 새 JSON 스키마 프롬프트 (profileSummary/prosCons/finalPick/riskNote) */
  private String buildJsonPrompt(List<FundListResponseDTO> funds, String profile) {
    DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    FundListResponseDTO A = funds.get(0), B = funds.get(1);

    StringBuilder sb = new StringBuilder();
    sb.append("당신은 한국어로 답변하는 펀드 애널리스트입니다.\n")
      .append("아래 두 펀드를 비교하여 '사용자 투자성향 요약, 펀드별 장단점, 최종 추천' 3섹션으로만 결과를 JSON으로 반환하세요.\n")
      .append("설명 문장, 마크다운, 코드펜스 없이 순수 JSON만 출력하십시오.\n\n")

      .append("JSON 스키마(키는 정확히 일치):\n")
      .append("{\n")
      .append("  \"profileSummary\": \"string\",\n")
      .append("  \"prosCons\": {\n")
      .append("    \"A\": { \"pros\": [\"string\"...], \"cons\": [\"string\"...] },\n")
      .append("    \"B\": { \"pros\": [\"string\"...], \"cons\": [\"string\"...] }\n")
      .append("  },\n")
      .append("  \"finalPick\": { \"pick\": \"A|B|tie\", \"reason\": \"string\" },\n")
      .append("  \"riskNote\": \"string\"\n")
      .append("}\n\n")

      .append("사용자 투자성향: ").append(profile).append("\n")
      .append("참고 원자료는 아래와 같으며, 장단점은 사실 기반으로 2~4개 안에서 간결히 작성하세요.\n")
      .append("A 펀드 정보:\n")
      .append("- 이름: ").append(nv(A.getFundName())).append("\n")
      .append("- 유형: ").append(nv(A.getFundType())).append("\n")
      .append("- 분류: ").append(nv(A.getFundDivision())).append("\n")
      .append("- 위험등급: ").append(nv(A.getRiskLevel())).append("\n")
      .append("- 운용사: ").append(nv(A.getManagementCompany())).append("\n")
      .append("- 설정일: ").append(A.getIssueDate() == null ? "-" : A.getIssueDate().format(fmt)).append("\n")
      .append("- 1M/3M/12M 수익률: ").append(nv(A.getReturn1m())).append(" / ")
                                 .append(nv(A.getReturn3m())).append(" / ")
                                 .append(nv(A.getReturn12m())).append("\n\n")

      .append("B 펀드 정보:\n")
      .append("- 이름: ").append(nv(B.getFundName())).append("\n")
      .append("- 유형: ").append(nv(B.getFundType())).append("\n")
      .append("- 분류: ").append(nv(B.getFundDivision())).append("\n")
      .append("- 위험등급: ").append(nv(B.getRiskLevel())).append("\n")
      .append("- 운용사: ").append(nv(B.getManagementCompany())).append("\n")
      .append("- 설정일: ").append(B.getIssueDate() == null ? "-" : B.getIssueDate().format(fmt)).append("\n")
      .append("- 1M/3M/12M 수익률: ").append(nv(B.getReturn1m())).append(" / ")
                                 .append(nv(B.getReturn3m())).append(" / ")
                                 .append(nv(B.getReturn12m())).append("\n\n");

    if ("미설정".equals(profile)) {
      sb.append("사용자 투자성향이 미설정이므로, 판단 기준은 '위험중립형(균형)'으로 가정하세요.\n");
    }

    sb.append("반드시 위 JSON 스키마 그대로만 출력하십시오.");
    return sb.toString();
  }

  private String callLlm(String msg) {
    return chatClient.prompt().user(msg).call().content();
  }

  /** ```/```json 제거, 스마트따옴표 정규화, 최외곽 {...} 추출 */
  private String extractPureJson(String raw) {
    if (raw == null) return null;
    String s = raw.trim();
    s = s.replaceAll("(?s)```json\\s*(.*?)\\s*```", "$1");
    s = s.replaceAll("(?s)```\\s*(.*?)\\s*```", "$1");
    s = s.replace('“','"').replace('”','"').replace('’','\'').replace('‘','\'');
    int i = s.indexOf('{'), j = s.lastIndexOf('}');
    if (i >= 0 && j > i) s = s.substring(i, j + 1);
    return s;
  }

  /** 유효 JSON인지 경량 검증(파싱만) */
  private String ensureJson(String json) {
    try { mapper.readTree(json); return json; }
    catch (Exception e) { return null; }
  }
}
