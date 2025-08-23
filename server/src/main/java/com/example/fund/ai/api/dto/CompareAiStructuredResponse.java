package com.example.fund.ai.api.dto;

import java.util.List;

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
public class CompareAiStructuredResponse  {
  private String summary;
  private List<Row> rows;
  private Recommendation recommendation;
  private String riskNote;

}
