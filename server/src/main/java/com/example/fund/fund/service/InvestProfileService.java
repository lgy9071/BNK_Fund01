package com.example.fund.fund.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

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
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class InvestProfileService {

    private final UserRepository userRepository;
    private final InvestProfileQuestionRepository questionRepository;
    private final InvestProfileTypeRepository typeRepository;
    private final InvestProfileResultRepository resultRepository;
    private final InvestProfileOptionRepository optionRepository;
    private final InvestProfileHistoryRepository historyRepository;

    public List<InvestProfileQuestion> findAllWithOptions() {
        return questionRepository.findAllWithOptions(); // 아래에 나오는 커스텀 쿼리 사용
    }

    // 점수 총합을 기반으로 투자성향 유형명 리턴
    public InvestProfileResult analyzeAndSave(Integer userId, Map<String, String> paramMap) {
        int totalScore = 0;
        System.out.println(paramMap);
        Map<String, Object> answerSnapshot = new LinkedHashMap<>();
        for (Map.Entry<String, String> entry : paramMap.entrySet()) {
            String key = entry.getKey(); // q0, q1 ..
            String value = entry.getValue();
            int questionNum = Integer.parseInt(key.replace("q", "")) + 1;

            // 체크박스 (복수 선택)
            if (key.equals("q8")) {
                String[] id = value.split(",");
                List<Integer> optionId = Arrays.stream(id).map(Integer::parseInt).collect(Collectors.toList());
                List<InvestProfileOption> options = optionRepository.findAllById(optionId);
                int sum = options.stream().mapToInt(InvestProfileOption::getScore).sum();
                totalScore += sum;
                List<Map<String, Object>> selectedList = options.stream()
                        .map(opt -> {
                            Map<String, Object> map = new HashMap<>();
                            map.put("selected_option", opt.getContent());
                            map.put("score", opt.getScore());
                            return map;
                        })
                        .collect(Collectors.toList());

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
                        .orElseThrow(() -> new RuntimeException("옵션 ID 오류: " + optionId));

                totalScore += option.getScore();

                Map<String, Object> snapshotEntry = new LinkedHashMap<>();
                snapshotEntry.put("question", option.getQuestion().getContent());
                snapshotEntry.put("selected_option", option.getContent());
                snapshotEntry.put("score", option.getScore());

                answerSnapshot.put(String.valueOf(questionNum), snapshotEntry);

            }
        }

        InvestProfileType type = typeRepository.findByScore(totalScore)
                .orElseThrow(() -> new RuntimeException("적절한 투자성향 유형이 없습니다."));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("사용자 없음"));

        // 스냅샷 JSON 변환
        String snapshotJson;
        try {
            snapshotJson = new ObjectMapper().writeValueAsString(answerSnapshot);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("JSON 변환 오류", e);
        }

        // 분석일
        LocalDateTime analysisTime = LocalDateTime.now();

        Optional<InvestProfileResult> existingResultOpt = resultRepository.findByUser_UserId(userId);

        InvestProfileResult result;

        if (existingResultOpt.isPresent()) {
            // 기존 결과 UPDATE
            result = existingResultOpt.get();
        } else {
            // 신규 INSERT
            result = new InvestProfileResult();
            result.setUser(user);
        }

        result.setAnswerSnapshot(snapshotJson);
        result.setTotalScore(totalScore);
        result.setType(type);
        result.setAnalysisDate(analysisTime);
        // result.setSignedAt(...); // 필요 시 사용

        InvestProfileResult savedResult = resultRepository.save(result);

        // 2. InvestProfileHistory 동시 저장
        InvestProfileHistory history = new InvestProfileHistory();
        history.setUser(user);
        history.setAnswerSnapshot(snapshotJson);
        history.setTotalScore(totalScore);
        history.setType(type);
        history.setAnalysisDate(analysisTime);
        history.setSignedAt(savedResult.getSignedAt()); // 필요시 null 가능

        historyRepository.save(history);

        return savedResult;
    }

    public Optional<InvestProfileResult> getLatestResult(User user) {
        Optional<InvestProfileResult> resultOpt = resultRepository.findTopByUserOrderByAnalysisDateDesc(user);

        if (resultOpt.isPresent()) {
            InvestProfileResult result = resultOpt.get();
            if (result.getAnalysisDate().plusDays(365).isBefore(LocalDateTime.now())) {
                return Optional.empty(); // 유효기간 초과 → 무효 처리
            }
        }

        return resultOpt;
    }

    public String extractAnswerText(String snapshotJson, String keyword) {
        try {
            ObjectMapper mapper = new ObjectMapper();
            Map<String, Object> snapshot = mapper.readValue(snapshotJson, new TypeReference<>() {
            });
            for (Object val : snapshot.values()) {
                Map<String, Object> entry = (Map<String, Object>) val;
                String question = entry.get("question").toString();
                if (question.contains(keyword)) {
                    if (entry.containsKey("selected_option")) {
                        return entry.get("selected_option").toString();
                    } else if (entry.containsKey("selected_options")) {
                        List<Map<String, Object>> opts = (List<Map<String, Object>>) entry.get("selected_options");
                        return opts.stream()
                                .map(o -> o.get("selected_option").toString())
                                .collect(Collectors.joining(", "));
                    }
                }
            }
        } catch (Exception e) {
            return "&nbsp;";
        }
        return "&nbsp;";
    }

    public boolean hasAnalyzedToday(Integer userId) {
        Optional<InvestProfileResult> opt = resultRepository.findByUser_UserId(userId);

        if (opt.isPresent()) {
            LocalDate lastDate = opt.get().getAnalysisDate().toLocalDate();
            return lastDate.isEqual(LocalDate.now()); // 오늘이면 true
        }

        return false;
    }
}
