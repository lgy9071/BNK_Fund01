package com.example.batch_scraper.job.chunk;

import java.util.Collections;
import java.util.List;

import org.springframework.batch.core.StepExecution;
import org.springframework.batch.core.StepExecutionListener;
import org.springframework.batch.item.ItemReader;
import org.springframework.stereotype.Component;

import com.example.batch_scraper.dto.FundRowData;

import lombok.extern.slf4j.Slf4j;


@Component
@Slf4j
public class FundListReader implements ItemReader<FundRowData>, StepExecutionListener {
    private List<FundRowData> fundList = Collections.emptyList();
    private int currentIndex = 0;

    // ExecutionContext에서 FundRowData 리스트 꺼내기
    @SuppressWarnings("unchecked")
    public void beforeStep(StepExecution stepExecution) {
    	log.info("4단계 - FundListReader - beforeStep - 이전 단계 데이터 받기");

		List<FundRowData> listFromContext = (List<FundRowData>) stepExecution
												.getJobExecution()
                                                .getExecutionContext()
                                                .get("fundRowDataList");

        if (listFromContext == null || listFromContext.isEmpty()) {
            log.warn("4단계 - FundListReader - beforeStep - fundRowDataList가 비어있음");
            this.fundList = Collections.emptyList();
        } else {
            this.fundList = listFromContext;
        }

        currentIndex = 0; // 인덱스 초기화
        log.info("4단계 - FundListReader - beforeStep - fundRowDataList 크기: {}", this.fundList.size());
    }
    
    
    @Override
    public FundRowData read() {
    	log.info("4단계 - FundListReader - 데이터 받고 processor에 전달");
    	if (currentIndex < fundList.size()) {
            return fundList.get(currentIndex++);
        }
        return null; // null 반환 시 Reader 종료
    }
    
}

/*

@BeforeStep
public void beforeStep(StepExecution stepExecution) {
    log.info("📋 FundListReader 초기화 시작");
    
    try {
        // JobExecutionContext에서 펀드 목록 가져오기
        ExecutionContext jobContext = stepExecution.getJobExecution().getExecutionContext();
        
        @SuppressWarnings("unchecked")
        List<Map<String, String>> fundList = (List<Map<String, String>>) jobContext.get("fundDataList");
        
        if (fundList == null || fundList.isEmpty()) {
            log.warn("⚠️ JobContext에서 펀드 목록을 찾을 수 없습니다!");
            this.fundDataList = List.of(); // 빈 리스트
            this.totalCount = 0;
        } else {
            this.fundDataList = fundList;
            this.totalCount = fundList.size();
        }
        
        this.currentIndex = 0;
        
        log.info("✅ FundListReader 초기화 완료");
        log.info("  - 총 처리 대상: {}개 펀드", totalCount);
        log.info("  - Chunk 크기: 10개 (약 {}개 청크 예상)", (totalCount + 9) / 10);
        
        // 첫 몇 개 펀드 미리보기
        if (totalCount > 0) {
            log.info("📦 처리 대상 펀드 미리보기:");
            for (int i = 0; i < Math.min(3, totalCount); i++) {
                Map<String, String> fund = fundDataList.get(i);
                log.info("  {}. {} ({})", 
                        i + 1, 
                        fund.getOrDefault("fundName", "Unknown"), 
                        fund.getOrDefault("fundCode", "N/A"));
            }
            if (totalCount > 3) {
                log.info("  ... 외 {}개", totalCount - 3);
            }
        }
        
    } catch (Exception e) {
        log.error("❌ FundListReader 초기화 실패", e);
        this.fundDataList = List.of();
        this.totalCount = 0;
        this.currentIndex = 0;
    }
}
 
 
@Override
public FundRowData read() {
    
    // 더 이상 읽을 데이터가 없으면 null 반환
    if (currentIndex >= totalCount) {
        log.info("📖 Reader 완료: 총 {}개 펀드 읽기 완료", totalCount);
        return null;
    }
    
    // 현재 인덱스의 펀드 데이터 반환
    Map<String, String> currentFund = fundDataList.get(currentIndex);
    currentIndex++;
    
    // 진행 상황 로깅 (매 10개마다)
    if (currentIndex % 10 == 0 || currentIndex == totalCount) {
        double progress = (double) currentIndex / totalCount * 100;
        log.info("📖 Reading 진행: {}/{} ({:.1f}%)", currentIndex, totalCount, progress);
    }
    
    // 개별 펀드 읽기 로그 (Debug 레벨)
    log.debug("📖 Reading: {} - {} ({})", 
            currentIndex, 
            currentFund.getOrDefault("fundName", "Unknown"),
            currentFund.getOrDefault("fundCode", "N/A"));
    
    return currentFund;
}
 
*/  
