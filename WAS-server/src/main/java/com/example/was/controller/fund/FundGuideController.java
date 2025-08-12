package com.example.was.controller.fund;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.example.fund.fund.entity.FundGuide;
import com.example.fund.fund.repository.FundGuideRepository;

@Controller
public class FundGuideController {
	
	@Autowired
	FundGuideRepository fundGuideRepository;

	@GetMapping("/guide")
	public String fundGuide(Model model) {
	    List<FundGuide> guideList1 = fundGuideRepository.findByCategory("유형");
	    List<FundGuide> guideList2 = fundGuideRepository.findByCategory("용어해설");

	    // 문장 단위로 자른 결과를 List<List<String>>으로 구성
	    List<List<String>> definitionSplitList = guideList2.stream()
	        .map(guide -> List.of(guide.getDefinition().split("\\.\\s*"))) // 꺼낸 데이터를 바꾸는 작업
	        .collect(Collectors.toList()); // 다시 리스트로 모으기

	    model.addAttribute("list1", guideList1);                 // 유형
	    model.addAttribute("list2", guideList2);                 // 용어해설 전체
	    model.addAttribute("splitList", definitionSplitList);    // 문장 단위 리스트

	    return "fundGuide";
	}

}
