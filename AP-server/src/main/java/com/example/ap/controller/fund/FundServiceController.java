package com.example.ap.controller.fund;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.example.common.dto.fund.FundRegisterRequest;
import com.example.ap.service.fund.FundService;        

@RestController
@RequestMapping("/fund")
@CrossOrigin(origins = "*")
public class FundServiceController {

    private final FundService fundService;

    public FundServiceController(FundService fundService) {
        this.fundService = fundService;
    }

    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> registerFund(
            @RequestPart("data") FundRegisterRequest request,
            @RequestPart("fileTerms") MultipartFile fileTerms,
            @RequestPart("fileManual") MultipartFile fileManual,
            @RequestPart("fileProspectus") MultipartFile fileProspectus) {

        try {
            Long fundId = fundService.registerFundWithAllDocuments(request, fileTerms, fileManual, fileProspectus);
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "message", "펀드 + 정책 + 문서 3종 등록 완료",
                    "fundId", fundId
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "status", "error",
                    "message", e.getMessage()
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "status", "error",
                    "message", "서버 오류: " + e.getMessage()
            ));
        }
    }


}

