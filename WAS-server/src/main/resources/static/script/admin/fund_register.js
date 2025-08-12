function openModal() {
  $('#fundModal').addClass('active');
}

function closeModal() {
  $('#fundModal').removeClass('active');
}

function searchFund() {
  const keyword = $('#searchKeyword').val();
  $.get('/api/funds/search/available', { name: keyword }, function(data) {
    let listHtml = '';
    data.forEach(fund => {
      listHtml += `<li onclick="selectFund('${fund.fundId}', '${fund.fundName}')">${fund.fundName}</li>`;
    });
    $('#fundResult').html(listHtml);
  }).fail((xhr, status, error) => {
    alert('검색 실패: ' + error);
  });
}

function selectFund(id, name) {
  $('#fundId').val(id);
  $('#fundName').val(name);
  closeModal();

  $.get(`/api/funds/${id}`, function(data) {
    $('#fundDetailBox').show();
    $('#fundType').text(data.fundType || '-');
    $('#investmentRegion').text(data.investmentRegion || '-');
    $('#establishDate').text(data.establishDate || '-');
    $('#totalExpenseRatio').text(data.totalExpenseRatio || '-');
    $('#riskLevel').text(data.riskLevel || '-');
    $('#managementCompany').text(data.managementCompany || '-');
  }).fail(() => {
    $('#fundDetailBox').hide();
    alert('펀드 정보를 불러오지 못했습니다.');
  });
}

function showTab(tabId) {
  $('.tab').removeClass('active');
  $('#' + tabId).addClass('active');
}

function closeConfirmModal() {
  window.location.href = '/admin/fund/list';
}

document.addEventListener('DOMContentLoaded', () => {
  // 등록 폼 제출
  document.getElementById('fundForm').addEventListener('submit', function(e) {
    e.preventDefault();

    document.getElementById('loadingOverlay').style.display = 'flex';

    const form = e.target;
    const formData = new FormData();

    const data = {
      fundId: form.fundId.value,
      fundTheme: form.fundTheme.value,
      fundPayout: "",
      fundActive: false,
      fundRelease: new Date().toISOString().slice(0, 10),
      docTitle: "",
      docType: "",
      fileFormat: "PDF"
    };

    formData.append("data", new Blob([JSON.stringify(data)], { type: "application/json" }));
    formData.append("fileTerms", form.fileTerms.files[0]);
    formData.append("fileManual", form.fileManual.files[0]);
    formData.append("fileProspectus", form.fileProspectus.files[0]);

    fetch('/fund/register', {
      method: 'POST',
      body: formData
    })
    .then(response => {
      document.getElementById('loadingOverlay').style.display = 'none';

      if (!response.ok) {
        throw new Error('등록 실패');
      }

      return response.json(); 
    })
    .then(result => {
      const fundId = result.fundId;

      document.getElementById('confirmModal').style.display = 'flex';

      document.getElementById('goToPayment').onclick = function () {
        window.location.href = `/admin/approval/form?fundId=${fundId}`;
      };
    })
    .catch(err => {
      document.getElementById('loadingOverlay').style.display = 'none';
      alert('오류 발생: ' + err.message);
    });
  });

  // 탭 파일 업로드 감지
  const fileToTabMap = {
    fileTerms: 'tab-terms',
    fileManual: 'tab-manual',
    fileProspectus: 'tab-prospectus'
  };

  Object.entries(fileToTabMap).forEach(([fileInputName, tabId]) => {
    const input = document.querySelector(`input[name="${fileInputName}"]`);
    const tab = document.getElementById(tabId);
    if (input && tab) {
      input.addEventListener('change', function () {
        tab.classList.toggle('file-attached', this.files.length > 0);
      });
    }
  });
});
