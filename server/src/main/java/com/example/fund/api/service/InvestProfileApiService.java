package com.example.fund.api.service;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.NOT_FOUND;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.example.fund.api.dto.investTest.RiskOptionDto;
import com.example.fund.api.dto.investTest.RiskQuestionDto;
import com.example.fund.api.dto.investTest.RiskQuestionListResponse;
import com.example.fund.api.dto.investTest.RiskResultView;
import com.example.fund.api.dto.investTest.RiskSubmitRequest;
import com.example.fund.fund.dto.InvestTypeResponse;
import com.example.fund.fund.entity.InvestProfileHistory;
import com.example.fund.fund.entity.InvestProfileOption;
import com.example.fund.fund.entity.InvestProfileQuestion;
import com.example.fund.fund.entity.InvestProfileResult;
import com.example.fund.fund.entity.InvestProfileType;
import com.example.fund.fund.repository.InvestProfileHistoryRepository;
import com.example.fund.fund.repository.InvestProfileOptionRepository;
import com.example.fund.fund.repository.InvestProfileQuestionRepository;
import com.example.fund.fund.repository.InvestProfileResultRepository;
import com.example.fund.fund.repository.InvestProfileTypeRepository;
import com.example.fund.user.entity.User;
import com.example.fund.user.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class InvestProfileApiService {

    private final UserRepository userRepository;
    private final InvestProfileQuestionRepository questionRepository;
    private final InvestProfileTypeRepository typeRepository;
    private final InvestProfileResultRepository resultRepository;
    private final InvestProfileOptionRepository optionRepository;
    private final InvestProfileHistoryRepository historyRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    /* ===== 조회 ===== */

    public RiskQuestionListResponse getQuestions(int uid) {
        // (필요시 uid 기반 가공 가능)
        List<InvestProfileQuestion> qs = questionRepository.findAllWithOptions();
        var questions = qs.stream().map(q -> new RiskQuestionDto(
                q.getQuestionId(),
                q.getContent(),
                q.getOptions().stream()
                        .map(o -> new RiskOptionDto(o.getOptionId(), o.getContent()))
                        .collect(Collectors.toList())))
                .toList();
        return new RiskQuestionListResponse(questions);
    }

    public RiskResultView getLatest(int uid) {
        User user = userRepository.findById(uid)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "사용자 없음"));

        Optional<InvestProfileResult> opt = resultRepository.findTopByUserOrderByAnalysisDateDesc(user);

        if (opt.isPresent()) {
            InvestProfileResult r = opt.get();
            String description = r.getType().getDescription();
            // 1년 유효기간 체크(기존 로직)
            if (r.getAnalysisDate().plusDays(365).isBefore(LocalDateTime.now())) {
                throw new ResponseStatusException(NOT_FOUND, "최근 결과 없음(유효기간 만료)");
            }
            return toView(r, description);
        }
        throw new ResponseStatusException(NOT_FOUND, "최근 결과 없음");
    }

    public Page<RiskResultView> getHistory(int uid, int page, int size) {
        User user = userRepository.findById(uid)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "사용자 없음"));
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "analysisDate"));
        Page<InvestProfileHistory> p = historyRepository.findByUser(user, pageable);
        return p.map(this::toView);
    }

    public boolean hasAnalyzedToday(Integer userId) {
        Optional<InvestProfileResult> opt = resultRepository.findByUser_UserId(userId);
        if (opt.isPresent()) {
            LocalDate lastDate = opt.get().getAnalysisDate().toLocalDate();
            return lastDate.isEqual(LocalDate.now()); // 오늘이면 true
        }
        return false;
    }

    public InvestTypeResponse getLatestSummary(int uid) {
        try {
            RiskResultView latest = getLatest(uid);
            // typeId가 필요한 경우 result 다시 로딩
            User user = userRepository.findById(uid)
                    .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "사용자 없음"));
            InvestProfileResult r = resultRepository.findTopByUserOrderByAnalysisDateDesc(user)
                    .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "최근 결과 없음"));
            Integer typeId = r.getType().getTypeId().intValue();
            return InvestTypeResponse.builder()
                    .hasProfile(true)
                    .investType(typeId)
                    .investTypeName(r.getType().getTypeName())
                    .build();
        } catch (ResponseStatusException e) {
            if (e.getStatusCode() == NOT_FOUND) {
                return InvestTypeResponse.builder()
                        .hasProfile(false)
                        .investType(null)
                        .investTypeName(null)
                        .build();
            }
            throw e;
        }
    }

    /* ===== 채점/저장 (신규 REST 경로) ===== */

    @Transactional
    public RiskResultView evaluateAndSave(int uid, RiskSubmitRequest request) {
        if (hasAnalyzedToday(uid)) {
            throw new ResponseStatusException(BAD_REQUEST, "오늘은 이미 투자성향 분석을 완료하셨습니다.");
        }

        // 채점 + 스냅샷 구성
        var calc = calculateScoreAndSnapshot(request);

        // 타입 매핑
        InvestProfileType type = typeRepository.findByScore(calc.totalScore())
                .orElseThrow(() -> new ResponseStatusException(BAD_REQUEST, "적절한 투자성향 유형이 없습니다."));

        User user = userRepository.findById(uid)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "사용자 없음"));

        // 저장(기존 로직 그대로)
        LocalDateTime analysisTime = LocalDateTime.now();
        String snapshotJson = writeJson(calc.snapshot());

        Optional<InvestProfileResult> existing = resultRepository.findByUser_UserId(uid);
        InvestProfileResult result = existing.orElseGet(InvestProfileResult::new);
        if (result.getUser() == null)
            result.setUser(user);

        result.setAnswerSnapshot(snapshotJson);
        result.setTotalScore(calc.totalScore());
        result.setType(type);
        result.setAnalysisDate(analysisTime);
        InvestProfileResult saved = resultRepository.save(result);

        // 히스토리도 저장
        InvestProfileHistory history = new InvestProfileHistory();
        history.setUser(user);
        history.setAnswerSnapshot(snapshotJson);
        history.setTotalScore(calc.totalScore());
        history.setType(type);
        history.setAnalysisDate(analysisTime);
        history.setSignedAt(saved.getSignedAt());
        historyRepository.save(history);

        String description = saved.getType().getDescription();

        return toView(saved, description);
    }

    /* ===== (호환) 기존 폼 paramMap 방식 ===== */

    @Transactional
    public RiskResultView evaluateAndSaveLegacy(int uid, Map<String, String> paramMap) {
        if (hasAnalyzedToday(uid)) {
            throw new ResponseStatusException(BAD_REQUEST, "오늘은 이미 투자성향 분석을 완료하셨습니다.");
        }

        int totalScore = 0;
        Map<String, Object> answerSnapshot = new LinkedHashMap<>();

        for (Map.Entry<String, String> e : paramMap.entrySet()) {
            String key = e.getKey(); // q0, q1 ...
            String value = e.getValue();
            int questionNum = Integer.parseInt(key.replace("q", "")) + 1;

            if (key.equals("q8")) { // 체크박스(복수)
                String[] ids = value.split(",");
                List<Integer> optionIds = Arrays.stream(ids).map(Integer::parseInt).toList();
                List<InvestProfileOption> options = optionRepository.findAllById(optionIds);
                int sum = options.stream().mapToInt(InvestProfileOption::getScore).sum();
                totalScore += sum;

                List<Map<String, Object>> selectedList = options.stream().map(opt -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("selected_option", opt.getContent());
                    m.put("score", opt.getScore());
                    return m;
                }).toList();

                if (!options.isEmpty()) {
                    String questionText = options.get(0).getQuestion().getContent();
                    Map<String, Object> snapshotEntry = new LinkedHashMap<>();
                    snapshotEntry.put("question", questionText);
                    snapshotEntry.put("selected_options", selectedList);
                    snapshotEntry.put("total_score", sum);
                    answerSnapshot.put(String.valueOf(questionNum), snapshotEntry);
                }
            } else {
                int optionId = Integer.parseInt(value);
                InvestProfileOption option = optionRepository.findById(optionId)
                        .orElseThrow(() -> new ResponseStatusException(BAD_REQUEST, "옵션 ID 오류: " + optionId));
                totalScore += option.getScore();

                Map<String, Object> snapshotEntry = new LinkedHashMap<>();
                snapshotEntry.put("question", option.getQuestion().getContent());
                snapshotEntry.put("selected_option", option.getContent());
                snapshotEntry.put("score", option.getScore());
                answerSnapshot.put(String.valueOf(questionNum), snapshotEntry);
            }
        }

        InvestProfileType type = typeRepository.findByScore(totalScore)
                .orElseThrow(() -> new ResponseStatusException(BAD_REQUEST, "적절한 투자성향 유형이 없습니다."));

        User user = userRepository.findById(uid)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "사용자 없음"));

        LocalDateTime analysisTime = LocalDateTime.now();
        String snapshotJson = writeJson(answerSnapshot);

        Optional<InvestProfileResult> existingResultOpt = resultRepository.findByUser_UserId(uid);
        InvestProfileResult result = existingResultOpt.orElseGet(InvestProfileResult::new);
        if (result.getUser() == null)
            result.setUser(user);

        result.setAnswerSnapshot(snapshotJson);
        result.setTotalScore(totalScore);
        result.setType(type);
        result.setAnalysisDate(analysisTime);
        InvestProfileResult savedResult = resultRepository.save(result);

        InvestProfileHistory history = new InvestProfileHistory();
        history.setUser(user);
        history.setAnswerSnapshot(snapshotJson);
        history.setTotalScore(totalScore);
        history.setType(type);
        history.setAnalysisDate(analysisTime);
        history.setSignedAt(savedResult.getSignedAt());
        historyRepository.save(history);

        String description = savedResult.getType().getDescription();

        return toView(savedResult, description);
    }

    /* ===== 내부 유틸 ===== */

    private record CalcResult(int totalScore, Map<String, Object> snapshot) {
    }

    // 신규 REST DTO 채점
    private CalcResult calculateScoreAndSnapshot(RiskSubmitRequest dto) {
        int totalScore = 0;
        Map<String, Object> snapshot = new LinkedHashMap<>();

        // questionId 오름차순으로 스냅샷 키 정렬(보기 좋게)
        var sorted = dto.answers().stream()
                .sorted(Comparator.comparingInt(RiskSubmitRequest.AnswerItem::questionId))
                .toList();

        for (int i = 0; i < sorted.size(); i++) {
            var ans = sorted.get(i);
            List<InvestProfileOption> options = optionRepository.findAllById(ans.optionIds());
            if (options.isEmpty()) {
                throw new ResponseStatusException(BAD_REQUEST, "옵션이 비어있습니다. questionId=" + ans.questionId());
            }

            int sum = options.stream().mapToInt(InvestProfileOption::getScore).sum();
            totalScore += sum;

            Map<String, Object> entry = new LinkedHashMap<>();
            entry.put("question", options.get(0).getQuestion().getContent());

            if (options.size() == 1) {
                entry.put("selected_option", options.get(0).getContent());
                entry.put("score", options.get(0).getScore());
            } else {
                List<Map<String, Object>> selectedList = options.stream().map(opt -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("selected_option", opt.getContent());
                    m.put("score", opt.getScore());
                    return m;
                }).toList();
                entry.put("selected_options", selectedList);
                entry.put("total_score", sum);
            }

            // 기존 스냅샷처럼 1부터 순번 부여
            snapshot.put(String.valueOf(i + 1), entry);
        }
        return new CalcResult(totalScore, snapshot);
    }

    private String writeJson(Object o) {
        try {
            return objectMapper.writeValueAsString(o);
        } catch (Exception e) {
            throw new ResponseStatusException(BAD_REQUEST, "JSON 변환 오류", e);
        }
    }

    private RiskResultView toView(InvestProfileResult r, String description) {
        return new RiskResultView(
                r.getResultId(),
                r.getTotalScore(),
                r.getType().getTypeName(),
                description, // profile은 간단히 typeName 재사용(필요시 description 요약)
                List.of(), // recommendations는 필요 시 채워넣기
                r.getAnalysisDate().toString());
    }

    private RiskResultView toView(InvestProfileHistory h) {
        return new RiskResultView(
                null,
                h.getTotalScore(),
                h.getType().getTypeName(),
                h.getType().getTypeName(),
                List.of(),
                h.getAnalysisDate().toString());
    }
}
