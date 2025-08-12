package com.example.ap.service.admin;

import java.util.ArrayList;
import java.util.List;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;

  @Service
  @RequiredArgsConstructor
  public class CompareAiService {

    private final ChatClient chatClient;

    private final FundRepository fundRepository;
    private final FundReturnRepository fundReturnRepository;

    // OpenAI의 답변 출력
    public String talk(String message) {
      return chatClient.prompt()
          .user(message)
          .call()
          .content();
    }

    public String fundsCompare(List<Long> fundIds, Integer investType) {

      List<FundPolicyResponseDTO> compareList = new ArrayList<>();

      // 펀드 ID리스트를 FundResponseDTO 리스트로 변환하는 for문
      for (Long id : fundIds) {
        Fund fund = fundRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Fund not found: " + id)); // 예외처리

        FundReturn fundReturn = fundReturnRepository.findByFund_FundId(id);
        if (fundReturn == null) {
          throw new RuntimeException("Fund return not found: " + id); // 예외처리
        }

        FundPolicyResponseDTO dto = FundPolicyResponseDTO.builder()
            .fundId(fund.getFundId())
            .fundName(fund.getFundName())
            .fundType(fund.getFundType())
            .investmentRegion(fund.getInvestmentRegion())
            .establishDate(fund.getEstablishDate())
            .launchDate(fund.getLaunchDate())
            .nav(fund.getNav())
            .aum(fund.getAum())
            .totalExpenseRatio(fund.getTotalExpenseRatio())
            .riskLevel(fund.getRiskLevel())
            .managementCompany(fund.getManagementCompany())
            .return1m(fundReturn.getReturn1m())
            .return3m(fundReturn.getReturn3m())
            .return6m(fundReturn.getReturn6m())
            .return12m(fundReturn.getReturn12m())
            .returnSince(fundReturn.getReturnSince())
            .build();

        compareList.add(dto);
      }
      String user_Invert = invertConvert(investType); // invert를 String으로 변환
      String message = buildFundComparisonPrompt(compareList, user_Invert); // 프롬프트 작성 함수 호출
      String result = talk(message);

      return result;
    }

    // 프롬프트 생성 함수
    public String buildFundComparisonPrompt(List<FundPolicyResponseDTO> fundResponseList, String investType) {
      StringBuilder promptBuilder = new StringBuilder();

      promptBuilder.append("다음은 비교하고 싶은 펀드들의 정보입니다.\n\n");
      promptBuilder.append("각 펀드의 이름, 총보수, 수익률(1개월, 3개월, 6개월, 12개월, 누적), 투자국가, 위험도가 포함되어 있습니다.\n\n");

      promptBuilder.append("또한 아래는 한 사용자의 투자 성향 분석 결과입니다. 이 성향에 가장 적합한 펀드를 알려주세요.\n\n");

      promptBuilder.append("⚠️ 다음 HTML 구조는 변경하지 말고, 내부에 내용만 채워 주세요.\n");
      promptBuilder.append("태그를 추가하거나 삭제하지 말고, 각 블록에 해당하는 내용을 작성해 주세요.\n");
      promptBuilder.append("불필요한 스타일이나 마크다운 문법은 사용하지 마세요.\n\n");
      promptBuilder.append("**를 사용하지 마세요. 파란색으로 표시해주세요.\n\n");

      promptBuilder.append("아래는 고정된 HTML 구조입니다. 변경하지마세요!!\n\n");
      promptBuilder.append("아래는 고정된 HTML 구조입니다. 여기에 내용을 채워 주세요:\n\n");

      promptBuilder.append("""
          <!-- 안내 문구 -->
            <div class="ai-notices">
              <p class="ai-reference-note">
                ※ 본 분석 결과는 AI가 생성한 참고용 정보이므로, 투자 결정 시 참고용으로만 활용해주세요.
              </p>
              <p class="ai-reload-note">
                ※ AI 분석 버튼을 다시 누르면 새로운 결과가 로딩됩니다.
              </p>
            </div>
            <div class="fund-comparison-result">

              <h2>사용자 투자 성향 요약</h2>
              <p class="investor-profile">
                [사용자 투자 성향 분석 결과 요약 내용 삽입]
              </p>

              <h2>수익성과 안정성 요약</h2>
              <p class="performance-summary">
                [수익성과 안정성에 대한 요약 내용 삽입]
              </p>

              <h2>펀드별 장단점</h2>
              <ul class="fund-pros-cons">
                [펀드별 항목으로 장점과 단점을 각각 <li> 로 구분하여 설명 삽입]
              </ul>

              <h2>추천 펀드 및 이유</h2>
              <p class="recommendation">
                [사용자에게 가장 적합한 펀드와 추천 이유 삽입]
              </p>

            </div>
            """);

      promptBuilder.append("\n아래 펀드 리스트와 투자 성향에 기반하여 위 HTML의 내용 부분을 채워 주세요.\n\n");

      promptBuilder.append("<h3>사용자 투자 성향 분석 결과</h3>\n");
      promptBuilder.append("<p>").append(investType).append("</p>\n\n");

      promptBuilder.append("<h3>펀드 데이터</h3>\n");
      for (FundPolicyResponseDTO fund : fundResponseList) {
        promptBuilder.append("- ").append(fund.getFundName()).append(" | 총보수: ")
            .append(fund.getTotalExpenseRatio()).append("% | 수익률(1M/3M/6M/12M/누적): ")
            .append(fund.getReturn1m()).append("/").append(fund.getReturn3m()).append("/")
            .append(fund.getReturn6m()).append("/").append(fund.getReturn12m()).append("/")
            .append(fund.getReturnSince()).append(" | 투자국가: ")
            .append(fund.getInvestmentRegion()).append(" | 위험도: ")
            .append(fund.getRiskLevel()).append("\n");
      }

      return promptBuilder.toString();
    }

    // 받아온 투자성향결과 Inteager -> String 변환 함수
    private String invertConvert(Integer invert) {
      String result = "";
      switch (invert) {
        case 1:
          result = "안정형";
          break;

        case 2:
          result = "안정 추구형";
          break;

        case 3:
          result = "위험 중립형";
          break;
        case 4:
          result = "적극 투자형";
          break;
        case 5:
          result = "공격 투자형";
          break;

        default:
          break;
      }

      return result;
    }
  }
