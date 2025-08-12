package com.example.was.controller.fund;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class FundMainController {
	
	@GetMapping("/fund")
	public String fundMain() {
		return "fundMain";
	}
}
