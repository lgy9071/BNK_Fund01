const resultMap = {
	  "AGG-PLAN-ANA-PATI-STEAD": {
	    title: "경제분석형",
	    description: "시장과 데이터를 기반으로 장기적 안목을 지닌 투자자입니다.",
	    tag: "#분석적장기투자자",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-PLAN-ANA-PATI-HIGH": {
	    title: "수익추구형",
	    description: "분석과 전략을 바탕으로 고수익을 추구하는 투자자입니다.",
	    tag: "#전략가 #고수익",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-PLAN-ANA-REACT-STEAD": {
	    title: "신중대응형",
	    description: "계획적으로 분석하지만 빠르게 반응할 줄 아는 투자자입니다.",
	    tag: "#계획형 #기민한",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-PLAN-ANA-REACT-HIGH": {
	    title: "분석공격형",
	    description: "계획과 분석력을 바탕으로 적극적인 수익을 추구합니다.",
	    tag: "#분석 #공격적투자",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-PLAN-TREND-PATI-STEAD": {
	    title: "트렌드분석형",
	    description: "시장 트렌드를 따르면서도 장기적인 성향을 유지합니다.",
	    tag: "#트렌드분석 #장기투자",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-PLAN-TREND-PATI-HIGH": {
	    title: "고수익트렌더",
	    description: "시장 흐름에 민감하며 고수익 기회를 노리는 투자자입니다.",
	    tag: "#트렌드 #수익형",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-PLAN-TREND-REACT-STEAD": {
	    title: "트렌드중시형",
	    description: "시장 흐름에 민감하게 반응하는 반응형 투자자입니다.",
	    tag: "#트렌드헌터",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-PLAN-TREND-REACT-HIGH": {
	    title: "공격형트렌더",
	    description: "변화에 즉각 대응하며 수익 극대화를 추구합니다.",
	    tag: "#즉응형 #공격투자자",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-FREE-ANA-PATI-STEAD": {
	    title: "직관분석형",
	    description: "자유롭게 접근하되 분석 기반으로 안정성을 추구합니다.",
	    tag: "#직관적 #분석형",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-FREE-ANA-PATI-HIGH": {
	    title: "자유수익형",
	    description: "분석보다는 직감과 수익성에 초점을 둔 투자자입니다.",
	    tag: "#자유형 #고수익지향",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-FREE-ANA-REACT-STEAD": {
	    title: "직관대응형",
	    description: "분석보다 반응에 강하며 균형 감각이 뛰어난 투자자입니다.",
	    tag: "#기민형 #직관형",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-FREE-ANA-REACT-HIGH": {
	    title: "공격직관형",
	    description: "감각적으로 움직이며 빠른 판단으로 수익을 추구합니다.",
	    tag: "#감투자 #스피드형",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-FREE-TREND-PATI-STEAD": {
	    title: "트렌드감성형",
	    description: "시장 감각에 민감하며 장기적 안정도 고려합니다.",
	    tag: "#감성형 #트렌디",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-FREE-TREND-PATI-HIGH": {
	    title: "감성수익형",
	    description: "트렌드를 타고 고수익을 노리는 감각적 투자자입니다.",
	    tag: "#감각형 #고위험",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-FREE-TREND-REACT-STEAD": {
	    title: "트렌드직감형",
	    description: "직관적이며 트렌드에 즉각 반응하는 균형잡힌 투자자입니다.",
	    tag: "#트렌디 #중립형",
	    image: "/images/mbti-char2.jpg"
	  },
	  "AGG-FREE-TREND-REACT-HIGH": {
	    title: "즉흥공격형",
	    description: "감각과 속도로 움직이는 민첩한 고위험 투자자입니다.",
	    tag: "#스피드투자 #고위험고수익",
	    image: "/images/mbti-char2.jpg"
	  },
	  "SAFE-PLAN-ANA-PATI-STEAD": {
	    title: "안정분석형",
	    description: "분석 기반의 안정형 투자자입니다.",
	    tag: "#분석형 #신중한",
	    image: "/images/mbti-char2.jpg"
	  }  ,
	  "SAFE-PLAN-ANA-PATI-HIGH": {
		    title: "신중수익형",
		    description: "분석 기반이지만 수익도 포기하지 않는 안정추구 투자자입니다.",
		    tag: "#신중 #수익추구",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-PLAN-ANA-REACT-STEAD": {
		    title: "보수대응형",
		    description: "계획적으로 분석하면서도 빠르게 반응할 수 있는 투자자입니다.",
		    tag: "#보수적 #기민한",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-PLAN-ANA-REACT-HIGH": {
		    title: "조심공격형",
		    description: "신중하지만 필요한 순간에는 공격적으로 움직일 수 있습니다.",
		    tag: "#신중공격형",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-PLAN-TREND-PATI-STEAD": {
		    title: "안정트렌더",
		    description: "트렌드를 관찰하면서도 안정적인 접근을 선호합니다.",
		    tag: "#트렌드 #안정형",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-PLAN-TREND-PATI-HIGH": {
		    title: "트렌드수익형",
		    description: "시장 흐름을 기반으로 수익을 추구하는 균형형 투자자입니다.",
		    tag: "#트렌디 #수익형",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-PLAN-TREND-REACT-STEAD": {
		    title: "보수트렌더",
		    description: "트렌드를 민감하게 따르지만 안정성을 중요시합니다.",
		    tag: "#트렌디 #안정추구",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-PLAN-TREND-REACT-HIGH": {
		    title: "민첩수익형",
		    description: "빠르게 시장에 반응하며 고수익을 노리는 조심스러운 투자자입니다.",
		    tag: "#신중하지만 #스피디",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-FREE-ANA-PATI-STEAD": {
		    title: "자유분석형",
		    description: "분석은 철저히 하지만 자유롭게 투자하는 스타일입니다.",
		    tag: "#자유형 #분석중시",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-FREE-ANA-PATI-HIGH": {
		    title: "분석수익형",
		    description: "분석을 바탕으로 고수익 상품을 찾는 자유로운 투자자입니다.",
		    tag: "#분석기반 #수익형",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-FREE-ANA-REACT-STEAD": {
		    title: "즉응형분석가",
		    description: "상황에 따라 움직이지만 기반은 분석입니다.",
		    tag: "#반응형 #분석중심",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-FREE-ANA-REACT-HIGH": {
		    title: "공격분석형",
		    description: "공격적으로 움직이지만 분석은 놓치지 않는 투자자입니다.",
		    tag: "#공격 #분석기반",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-FREE-TREND-PATI-STEAD": {
		    title: "감각안정형",
		    description: "트렌드를 살피되 안정적인 상품 위주로 구성합니다.",
		    tag: "#감성형 #안정지향",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-FREE-TREND-PATI-HIGH": {
		    title: "감성수익형",
		    description: "트렌드와 감을 바탕으로 수익을 노리는 투자자입니다.",
		    tag: "#감각 #수익형",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-FREE-TREND-REACT-STEAD": {
		    title: "민첩안정형",
		    description: "빠른 반응을 하되, 안정적인 방향으로 유지합니다.",
		    tag: "#신중기민 #안정중심",
		    image: "/images/mbti-char2.jpg"
		  },
		  "SAFE-FREE-TREND-REACT-HIGH": {
		    title: "즉흥형감성투자자",
		    description: "감각적으로 반응하며 수익을 노리는 투자자입니다.",
		    tag: "#감각형 #고수익 #유연함",
		    image: "/images/mbti-char2.jpg"
		  }

	};