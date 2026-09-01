const fmt = new Intl.NumberFormat('pt-BR');

async function loadDashboard(){
  const response = await fetch('/api/dashboard');
  const data = await response.json();
  if(!response.ok) throw new Error(data.detail || data.error);
  document.querySelector('#mode').textContent = data.mode === 'oracle' ? 'Oracle conectado' : 'modo demonstrativo';
  document.querySelector('#notice').textContent = data.notice;
  for(const [key,id] of Object.entries({internacoes:'kpi-internacoes',obitos:'kpi-obitos',permanencia_dias:'kpi-permanencia',hospitais:'kpi-hospitais'})){
    document.querySelector('#'+id).textContent = fmt.format(data.kpis[key] || 0);
  }
  new Chart(document.querySelector('#trendChart'),{type:'line',data:{labels:data.trend.map(x=>x.competencia),datasets:[{label:'Internações',data:data.trend.map(x=>x.internacoes),borderColor:'#147d7b',tension:.3},{label:'Óbitos',data:data.trend.map(x=>x.obitos),borderColor:'#d46f50',tension:.3}]},options:{responsive:true,maintainAspectRatio:false}});
  document.querySelector('#pressure').innerHTML = data.pressure.map(x=>`<li><span>${x.hospital}<small>${x.municipio}</small></span><strong>${Number(x.pressao_pct).toLocaleString('pt-BR')}%</strong></li>`).join('');
  new Chart(document.querySelector('#comorbidityChart'),{type:'bar',data:{labels:data.comorbidities.map(x=>x.cid),datasets:[{label:'Internações',data:data.comorbidities.map(x=>x.internacoes),backgroundColor:'#1f4f75'}]},options:{responsive:true,maintainAspectRatio:false,plugins:{tooltip:{callbacks:{afterLabel:c=>data.comorbidities[c.dataIndex].descricao}}}}});
  if(data.predictions.length){document.querySelector('#predictions').innerHTML=data.predictions.map(x=>`<p><strong>${x.hospital}</strong> · ${x.horizonte_meses} mês(es) · ${Number(x.pressao_prevista_pct).toLocaleString('pt-BR')}% · ${x.nivel_risco}</p>`).join('');}
}

document.querySelector('#ask-form').addEventListener('submit',async event=>{
  event.preventDefault(); const status=document.querySelector('#ai-status'); const sql=document.querySelector('#ai-sql'); const answer=document.querySelector('#ai-answer');
  status.textContent='Consultando o Oracle Select AI…'; sql.hidden=true; answer.textContent='';
  const response=await fetch('/api/select-ai',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({pergunta:document.querySelector('#question').value})});
  const data=await response.json(); status.textContent=response.ok?'Consulta concluída.':(data.error||'Falha na consulta.');
  if(response.ok){sql.textContent=data.sql||'';sql.hidden=!data.sql;answer.textContent=data.resposta||'';}else if(data.required){answer.textContent=data.required;}
});

loadDashboard().catch(error=>{document.querySelector('#notice').textContent='Não foi possível carregar o dashboard: '+error.message;});

