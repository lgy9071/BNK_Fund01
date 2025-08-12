package com.example.ap.controller.admin;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;


@RestController
@RequestMapping("/ai")
public class CompareAiController {

    @Autowired
    private CompareAiService compareAiService;

    @GetMapping("/compare")
    public String fundCompare(@RequestParam("fundId") List<Long> fundId, @RequestParam("invert") Integer invert) {

        String result = compareAiService.fundsCompare(fundId, invert);
        return result;
    }

}
