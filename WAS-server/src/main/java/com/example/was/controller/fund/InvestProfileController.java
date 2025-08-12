package com.example.was.controller.fund;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.server.ResponseStatusException;

import com.example.common.entity.fund.InvestProfileQuestion;
import com.example.common.entity.fund.InvestProfileResult;
import com.example.common.entity.fund.User;
import com.example.fund.fund.service.InvestProfileService;

import jakarta.servlet.http.HttpSession;

@Controller
public class InvestProfileController {
	
	@Autowired
	InvestProfileService investProfileService;
	
	@GetMapping("/profile")
	public String investProfile(HttpSession session, Model model) {
	    User loginUser = (User)session.getAttribute("user");
	    if (loginUser == null) return "redirect:/auth/login";

	    model.addAttribute("user", loginUser);

	    Optional<InvestProfileResult> optional = investProfileService.getLatestResult(loginUser);
	    boolean analyzedToday = investProfileService.hasAnalyzedToday(loginUser.getUserId());
	    model.addAttribute("analyzedToday", analyzedToday);

	    if (optional.isPresent()) {
	        InvestProfileResult result = optional.get();
	        model.addAttribute("result", result);
	        model.addAttribute("riskType", result.getType().getTypeName());
	        model.addAttribute("lastChanged", result.getAnalysisDate().toLocalDate());
	        model.addAttribute("canInvestTerm", investProfileService.extractAnswerText(result.getAnswerSnapshot(), "투자가능기간"));
	        model.addAttribute("experienceTerm", investProfileService.extractAnswerText(result.getAnswerSnapshot(), "투자경험기간"));
	    } else {
	        model.addAttribute("riskType", "설문대상자");
	        model.addAttribute("lastChanged", "&nbsp;");
	        model.addAttribute("canInvestTerm", "&nbsp;");
	        model.addAttribute("experienceTerm", "&nbsp;");
	    }

	    return "investprofile";
	}

	
	 @GetMapping("/terms")
	 public String showInvestProfileForm(Model model, HttpSession session) {
		User loginUser = (User)session.getAttribute("user");
		if (loginUser == null) return "redirect:/auth/login";
	    List<InvestProfileQuestion> questions = investProfileService.findAllWithOptions();
	    model.addAttribute("questions", questions);
	    model.addAttribute("user", loginUser.getName());
	    return "terms"; // templates/investProfile.html
	 }
	 
	 @PostMapping("/analyze-ajax")
	 @ResponseBody
	 public Map<String, Object> analyzeAjax(@RequestParam Map<String, String> paramMap, HttpSession session) {
	     User loginUser = (User) session.getAttribute("user");
	     if (loginUser == null) {
	         throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
	     }
	     if (investProfileService.hasAnalyzedToday(loginUser.getUserId())) {
	         throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "오늘은 이미 투자성향 분석을 완료하셨습니다.");
	     }
	     // 분석 수행 및 결과 저장
	     InvestProfileResult result = investProfileService.analyzeAndSave(loginUser.getUserId(), paramMap);

	     Map<String, Object> response = new HashMap<>();
	     response.put("typeName", result.getType().getTypeName());
	     response.put("description", result.getType().getDescription());
	     response.put("totalScore", result.getTotalScore()); // 게이지 차트용

	     return response;
	 }
	 
	 

}
