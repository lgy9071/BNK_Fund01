package com.example.fund.admin.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.admin.service.CustomerService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/admin/api/customers")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerService service;

    @GetMapping("/search")
    public List<CustomerService.ListItem> search(@RequestParam("q") String q){
        return service.search(q);
    }

    @GetMapping("/{id}")
    public CustomerService.Detail detail(@PathVariable Long id){
        return service.getDetail(id);
    }
}
