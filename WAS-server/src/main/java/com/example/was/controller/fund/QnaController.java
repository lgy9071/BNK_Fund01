package com.example.was.controller.fund;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.example.common.dto.fund.QnaDto;
import com.example.common.entity.fund.Qna;
import com.example.common.entity.fund.User;
import com.example.fund.qna.repository.QnaRepository;
import com.example.fund.qna.service.QnaService;

import jakarta.servlet.http.HttpSession;

@Controller
public class QnaController {

	@Autowired
	QnaRepository qnaRepository;

	@Autowired
	QnaService qnaService;

	@GetMapping("/qna")
	public String qnaPage(HttpSession session, Model model) {
		User loginUser = (User) session.getAttribute("user");
		if (loginUser == null) {
			return "redirect:/auth/login";
		}
		model.addAttribute("user", loginUser);
		return "qna";
	}

	@PostMapping("/regQna")
	@ResponseBody
	public Map<String, Object> regQna(@RequestBody Qna qna, HttpSession session) {
		User loginUser = (User) session.getAttribute("user");
		qna.setStatus("대기");
		qna.setUser(loginUser);
		qnaRepository.save(qna);

		Map<String, Object> result = new HashMap<>();
		result.put("result", "success");
		result.put("redirectUrl", "/qnaSuccess");

		return result;
	}

	@GetMapping("qnaSuccess")
	public String qnaSuccess(HttpSession session) {
		User loginUser = (User) session.getAttribute("user");
		if (loginUser == null) {
			return "redirect:/auth/login";
		}
		return "qna_success";
	}

	@GetMapping("/admin/qna")
	public String listQnaByStatus(@RequestParam(defaultValue = "대기") String status,
			@RequestParam(defaultValue = "0") int page,
			Model model) {
		List<Qna> qnaList = qnaService.getQnaList(status);

		Page<Qna> qnaPage = qnaService.getQnaListByStatus(status, page);
		model.addAttribute("qnaList", qnaPage.getContent());
		model.addAttribute("page", qnaPage);

		if (qnaList == null) {
			qnaList = new ArrayList<>();
		}

		if (status.equals("완료")) {
			model.addAttribute("qnaList", qnaPage.getContent());
			model.addAttribute("page", qnaPage);
			return "admin/cs/qnaList :: qna-AnsweredList";
		}

		model.addAttribute("qnaList", qnaList);

		return "admin/cs/qnaList :: qna-UnAnsweredList";
	}

	@GetMapping("/admin/qna/detail/{qnaId}")
	public String showQnaDetail(@PathVariable("qnaId") Integer id, Model model) {
		Qna qna = qnaService.getQna(id);
		model.addAttribute("qna", qna);
		return "admin/cs/qnaDetailAndAnswer";
	}

	@PostMapping("/admin/qna/answer")
	public String answer(@RequestParam("id") Integer qnaId,
			@RequestParam("answer") String answer,
			RedirectAttributes rttr) {
		qnaService.SubmitAnswer(qnaId, answer);

		String msg = "답변이 성공적으로 등록되었습니다";
		rttr.addFlashAttribute("msg", msg);

		return "redirect:/admin/qnaList";
	}

	@GetMapping("/admin/qna/answeredDetail/{qnaId}")
	public String showAnsweredQnaDetail(@PathVariable("qnaId") Integer id, Model model) {
		Qna qna = qnaService.getQna(id);
		model.addAttribute("qna", qna);

		return "admin/cs/qnaAnsweredDetail";
	}

	@GetMapping("/qna/{qnaId}")
	public String qnaDetail(@PathVariable Long qnaId, Model model, HttpSession session) {
		User user = (User) session.getAttribute("user");
		if (user == null)
			return "redirect:/auth/login";

		Qna qna = qnaService.getQnaById(qnaId); // 서비스에서 가져오기
		model.addAttribute("qna", qna);
		return "mypage/qna-detail";
	}

	@GetMapping("/mypage/qna/{qnaId}")
	public String mypageQnaDetailAjax(
			@PathVariable Long qnaId,
			HttpSession session, Model model) {

		User user = (User) session.getAttribute("user");
		if (user == null) {
			// 인증 안 된 경우 401 리턴
			return "fragments/empty :: empty";
		}

		Qna qna = qnaService.getQnaById(qnaId);
		QnaDto dto = new QnaDto(
				qna.getQnaId(),
				qna.getTitle(),
				qna.getContent(),
				qna.getRegDate(),
				qna.getStatus(),
				qna.getAnswer());
		System.out.println(dto);
		model.addAttribute("qna", dto);
		return "fragments/qnaDetailModal :: qnaDetailModal";
	}
}
