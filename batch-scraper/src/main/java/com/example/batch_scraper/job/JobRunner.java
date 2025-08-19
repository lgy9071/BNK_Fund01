package com.example.batch_scraper.job;

import java.time.LocalDate;
import java.time.ZoneId;

import org.springframework.batch.core.Job;
import org.springframework.batch.core.JobExecution;
import org.springframework.batch.core.JobParameters;
import org.springframework.batch.core.JobParametersBuilder;
import org.springframework.batch.core.JobParametersInvalidException;
import org.springframework.batch.core.explore.JobExplorer;
import org.springframework.batch.core.launch.JobLauncher;
import org.springframework.batch.core.repository.JobExecutionAlreadyRunningException;
import org.springframework.batch.core.repository.JobInstanceAlreadyCompleteException;
import org.springframework.batch.core.repository.JobRestartException;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StopWatch;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class JobRunner implements ApplicationRunner {
	private final JobLauncher jobLauncher;
	private final Job job;
	private final JobExplorer jobExplorer;

	@Override
	public void run(ApplicationArguments args) {
		// safeRun("startup");
		runJob("startup");
	}

	/** 동시 실행 방지용 래퍼 */
	public void safeRun(String trigger) {
		if (!jobExplorer.findRunningJobExecutions(job.getName()).isEmpty()) {
			log.warn("⏳ [{}] 이미 실행 중이어서 스킵합니다.", job.getName());
			return;
		}
		runJob(trigger);
	}

	/** 펀드 스크래핑 Job 실행 */
	@Transactional(isolation = Isolation.READ_COMMITTED)
	public void runJob(String trigger) {
		String runDate = LocalDate.now(ZoneId.of("Asia/Seoul")).toString();				// 예: 매일 실행이라면 오늘 날짜를 비즈니스 키로 사용

		JobParameters params = new JobParametersBuilder().addString("runDate", runDate) // 비즈니스 키(재시작/중복제어에 유리)
				.addString("trigger", trigger) // 실행 트리거 구분 (startup/schedule/manual 등)
				.addLong("run.id", System.currentTimeMillis()) // 유니크 보장(Incrementer 대용)
				.toJobParameters();

		StopWatch sw = new StopWatch(job.getName());
		sw.start();
		log.info("JobRunner - 실행 시작");
		// log.info("🚀 Job 실행 시작: name={}, params={}", job.getName(), params);

		try {
			JobExecution exec = jobLauncher.run(job, params);
			log.info("JobRunner - 실행 종료");
		} catch (JobExecutionAlreadyRunningException | JobRestartException | JobInstanceAlreadyCompleteException | JobParametersInvalidException e) {
			log.error("JobRunner - 실행 실패: {}", e);
		} catch (Exception e) {
			log.error("JobRunner - 예상치 못한 예외로 Job 실행 실패: {}", e);
		} finally {
            sw.stop();
            log.info("JobRunner - 배치 처리 소요시간: {} ms", sw.getTotalTimeMillis());
            log.info("────────────────────────────────────────────");
		}
	}
}

//@Component
//@RequiredArgsConstructor
//@Slf4j
//public class JobRunner implements ApplicationRunner {
//    private final JobLauncher jobLauncher;
//    private final Job scrapingJob;
//    
//	@Override
//	public void run(ApplicationArguments args) throws Exception {
//		try {
//			runJob();
//        } catch (Exception e) {
//            log.error("❌ 시작시 Job 실행 실패", e);
//        }
//	}
//
//	펀드 스크래핑 Job 실행
//    public void runJob() {
//        String currentTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
//        log.info("===== Job 실행 시작 ===== [{}]", currentTime);
//        
//        try {
//            log.info("🚀 펀드 스크래핑 Job 실행 시작");
//            JobParameters jobParameters = new JobParametersBuilder()
//                    .addLong("timestamp", System.currentTimeMillis())
//                    .toJobParameters();
//            jobLauncher.run(scrapingJob, jobParameters);
//            log.info("===== Job 실행 완료 ===== [{}]", currentTime);
//        } catch (Exception e) {
//            log.error("❌ 펀드 스크래핑 Job 실행 실패", e);
//        } finally {
//            log.info("────────────────────────────────────────────");
//        }
//    }
//}