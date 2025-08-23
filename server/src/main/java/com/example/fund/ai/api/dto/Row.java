package com.example.fund.ai.api.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data 
@NoArgsConstructor 
@AllArgsConstructor 
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class Row {
    private String item;
    private String a;
    private String b;
    private String winner;   // "A" | "B" | "tie" | "unknown"
    private String comment;
}
