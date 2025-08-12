package com.example.was.controller.fund;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.data.web.SpringDataWebProperties.Pageable;
import org.springframework.boot.autoconfigure.data.web.SpringDataWebProperties.Sort;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.example.common.entity.fund.Faq;
import com.example.fund.faq.repository.FaqRepository;

@Controller
public class FaqController {

    @Autowired
    private FaqRepository faqRepository;

    @GetMapping("/faq")
    public String faqPage() {
        return "faq"; // templates/faq.html
    }

    @GetMapping("/searchFaq")
    @ResponseBody
    public Map<String, Object> searchFaq(
            @RequestParam(name = "keyword", required = false, defaultValue = "") String keyword,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "10") int size
    ) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("faqId").descending());
        Page<Faq> faqPage = faqRepository.searchActiveFaqs(keyword, pageable);

        Map<String, Object> response = new HashMap<>();
        response.put("content", faqPage.getContent());
        response.put("totalPages", faqPage.getTotalPages());
        response.put("currentPage", faqPage.getNumber());

        return response;
    }

}
