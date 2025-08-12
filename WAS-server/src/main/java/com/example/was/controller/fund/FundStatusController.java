package com.example.was.controller.fund;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

import com.example.common.entity.fund.FundStatus;

import jakarta.servlet.http.HttpSession;

@Controller
public class FundStatusController {
	
	@Autowired
	FundStatusService statusService;
	
	@GetMapping("/fund_status")
	public String fundStatusPage(@RequestParam(name="page", defaultValue="0") int page,
								 @RequestParam(name = "keyword", required = false, defaultValue = "") String keyword,
								 Model model) {
		Page<FundStatus> fundPage = statusService.getPagedStatusListByKeyword(page, 10, keyword);
		model.addAttribute("statusList", fundPage.getContent());
		
		model.addAttribute("totalCount", fundPage.getTotalElements());
		model.addAttribute("totalPages", fundPage.getTotalPages()); // 전체 페이지 수
	    model.addAttribute("currentPage", page); // 현재 페이지 번호
        model.addAttribute("keyword", keyword); // 검색어
		return "fund_status";
	}
	
	@GetMapping("/fund_status_detail/{id}")
	public String detailPage(@PathVariable("id") Integer id, Model model, HttpSession session) {
		
		String sessionKey ="viewed_post_" + id;
		// 세션에 이 게시글 조회 기록이 없을 때만 조회수 증가
		if(session.getAttribute(sessionKey) == null) {
			statusService.incrementViewCount(id);
			session.setAttribute(sessionKey, true);
		}
		
		FundStatus fund = statusService.getDetail(id);

		model.addAttribute("fund", fund);
		model.addAttribute("prev", statusService.getPrevStatus(id));
        model.addAttribute("next", statusService.getNextStatus(id));
		return "status_detail";
	}
}
