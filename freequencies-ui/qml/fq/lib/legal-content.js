.pragma library
// Legal toolkit content: legal INFORMATION for promoters in Portugal, not advice. Portuguese first.
// Researched from official sources on 2026-11-25 (see each item's sources). Items marked
// `uncertain` could not be confirmed against the primary text and show "to confirm" in the app.
// REVIEWED stays false until a lawyer or legal clinic has reviewed this file.
// When the law changes: update the item, its sources and LAST_CHECKED.

var LAST_CHECKED = "2026-11-25"
var REVIEWED = false

// ── legal forms ──
var FORMS = {
    informal: {
        title: { pt: "Coletivo informal", en: "Informal collective" },
        body: {
            pt: "Podem organizar sem registar nada, mas a lei trata o grupo como associação sem personalidade jurídica (ou «comissão especial» se for para um evento). As dívidas pagam-se primeiro do fundo comum; se não chegar, quem assinou ou agiu responde pessoal e solidariamente, e depois os restantes membros. Sem NIPC não podem assinar contratos ou arrendamentos, abrir conta, faturar como entidade, nem candidatar-se à maioria dos apoios municipais. Custo: zero.",
            en: "You can organise without registering, but the law treats the group as an association without legal personality (or an «event committee»). Debts are paid first from the common fund; if that's not enough, whoever signed or acted is personally and jointly liable, then the other members. Without a tax number for the group you can't sign contracts or leases, open a bank account, invoice as an entity, or apply for most municipal funding. Cost: nothing."
        },
        sources: ["https://www.pgdlisboa.pt/leis/lei_mostra_articulado.php?nid=775&tabela=leis"]
    },
    association: {
        title: { pt: "Associação cultural (sem fins lucrativos)", en: "Cultural association (non-profit)" },
        body: {
            pt: "Uma pessoa coletiva com NIPC: assina contratos, recebe apoios e protege o património pessoal dos membros. Com a «Associação na Hora» (IRN) fica feita no mesmo dia, com estatutos-modelo: pelo menos 2 fundadores presentes e quem fica nos órgãos; custa 300 €. Precisa de assembleia geral (reúne pelo menos uma vez por ano para aprovar contas), direção e conselho fiscal. Depois: declarar início de atividade às Finanças em 90 dias. Algumas isenções de IVA aplicam-se a associações (ex.: quotas dos sócios, ensino ou prática artística), mas não são uma isenção geral para bilhetes de concertos.",
            en: "A legal person with its own tax number: it signs contracts, receives grants and protects members' personal assets. With «Associação na Hora» (IRN) it's done the same day using model statutes: at least 2 founders present plus everyone joining the governing bodies; it costs €300. It needs a general assembly (meeting at least once a year to approve the accounts), a board and an audit board. Afterwards: declare the start of activity to the tax office within 90 days. Some VAT exemptions apply to associations (members' fees, teaching or practising an art), but they're not a general exemption for concert tickets."
        },
        sources: ["https://www.gov.pt/servicos/criar-uma-associacao-na-hora", "https://www.gov.pt/guias/participacao-civica/participacao-civica-criar-e-fazer-parte-de-associacoes",
                  "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/civa_rep/Pages/iva9.aspx"]
    },
    company: {
        title: { pt: "Empresa ou trabalhador independente", en: "Company or self-employed" },
        body: {
            pt: "Uma Lda ou unipessoal limita a responsabilidade mas é para ter lucro: contabilidade organizada e contabilista certificado (capital mínimo 1 € por quota; «Empresa na Hora» cerca de 360 €). Como trabalhador independente passas «recibos verdes» no Portal das Finanças; quem te paga com contabilidade organizada retém 23% de IRS, salvo se previres menos de 15 000 €/ano e escreveres «Sem retenção». Isenção de IVA (art. 53.º) até 15 000 € de volume de negócios. Quem contrata profissionais da cultura paga 5,1% à Segurança Social (Estatuto dos Profissionais da Área da Cultura).",
            en: "A limited company (Lda / unipessoal) limits liability but is for profit: formal accounting and a certified accountant (minimum capital €1 per quota; «Empresa na Hora» about €360). Self-employed, you issue «recibos verdes» on the tax portal; clients with formal accounting withhold 23% income tax, unless you expect under €15,000 a year and write «Sem retenção». VAT exemption (art. 53) up to €15,000 turnover. Whoever hires culture professionals pays 5.1% to Social Security (Culture Professionals' Statute)."
        },
        sources: ["https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs101.aspx",
                  "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/civa_rep/Pages/artigo-53-o-do-civa.aspx",
                  "https://diariodarepublica.pt/dr/legislacao-consolidada/decreto-lei/2021-175043541"]
    }
}

// ── papers for an event in Lisbon ──
var PAPERS = [
    { key: "igac",
      title: { pt: "Registo de promotor e comunicação do espetáculo (IGAC)", en: "Promoter registration and show notice (IGAC)" },
      what: { pt: "Quem promove espetáculos tem de estar registado na IGAC. Exceção: associações sem fins lucrativos com até 3 espetáculos por ano («promotor ocasional»), que só se autenticam no balcão digital. Cada espetáculo exige uma mera comunicação prévia (via ePortugal) até ao início, com as obras a interpretar e a classificação etária.",
              en: "Promoters must be registered with IGAC. Exception: non-profits putting on up to 3 shows a year («occasional promoter»), who only authenticate on the digital counter. Each show needs a simple prior notice (via ePortugal) by the time it starts, listing the works performed and the age rating." },
      who: { pt: "IGAC", en: "IGAC" }, time: { pt: "Desconhecido", en: "Unknown" },
      cost: { pt: "Registo cerca de 200 € online (a confirmar)", en: "Registration about €200 online (to confirm)" },
      without: { pt: "Contraordenação", en: "An administrative offence" },
      uncertain: true,
      sources: ["https://diariodarepublica.pt/dr/legislacao-consolidada/decreto-lei/2014-122960410", "https://www.igac.gov.pt/servicos/catalogo-de-servicos/promotores/registo-de-promotor-de-espetaculos-de-natureza-artistica"] },
    { key: "venue",
      title: { pt: "Licença de recinto improvisado (Câmara)", en: "Temporary venue licence (Câmara)" },
      what: { pt: "Um espaço adaptado ou com estruturas temporárias (tenda, palco, bancadas) para um espetáculo precisa de licença da Câmara. O pedido inclui planta, plano de evacuação, lotação, instalações sanitárias, certificados dos equipamentos e seguros de responsabilidade civil e de acidentes pessoais. A Câmara decide em 5 dias úteis.",
              en: "A space adapted or fitted with temporary structures (tent, stage, stands) for a show needs a licence from the Câmara. The application includes a layout plan, evacuation plan, capacity, toilets, equipment certificates and liability plus personal-accident insurance. The Câmara decides within 5 working days." },
      who: { pt: "Câmara Municipal de Lisboa (fiscalização: ASAE, PSP)", en: "Lisbon City Council (inspection: ASAE, PSP)" }, time: { pt: "5 dias úteis para decidir", en: "5 working days to decide" },
      cost: { pt: "Taxa municipal (valor a confirmar)", en: "Municipal fee (amount to confirm)" },
      without: { pt: "Contraordenação económica; a PSP já autuou espaços em Lisboa por falta desta licença", en: "An economic offence; PSP has fined Lisbon venues for not having it" },
      sources: ["https://diariodarepublica.pt/dr/detalhe/decreto-lei/268-2009-490708", "https://observador.pt/2023/03/14/psp-instaura-dois-autos-por-falta-de-licenca-de-recinto-de-diversao-noturna-em-lisboa/"] },
    { key: "noise",
      title: { pt: "Licença especial de ruído (Câmara)", en: "Special noise licence (Câmara)" },
      what: { pt: "Atividades ruidosas temporárias (espetáculos, festas) perto de casas, escolas ou hospitais estão limitadas à noite, ao fim de semana e feriados. A Câmara pode autorizá-las com licença especial, a título excecional, e define as condições. Pede com pelo menos 15 dias úteis de antecedência.",
              en: "Temporary noisy activities (shows, parties) near homes, schools or hospitals are restricted at night, at weekends and on holidays. The Câmara can allow them with a special licence, as an exception, and sets the conditions. Apply at least 15 working days ahead." },
      who: { pt: "Câmara Municipal de Lisboa (fiscalização: PSP, Polícia Municipal)", en: "Lisbon City Council (enforced by PSP, Municipal Police)" }, time: { pt: "15 dias úteis ou mais", en: "15 working days or more" },
      cost: { pt: "Desconhecido", en: "Unknown" },
      without: { pt: "Contraordenação ambiental (cerca de 200 € a 2 000 €) e a polícia pode parar o evento", en: "Environmental offence (about €200 to €2,000) and police can stop the event" },
      uncertain: true,
      sources: ["https://diariodarepublica.pt/dr/detalhe/decreto-lei/9-2007-522807"] },
    { key: "hours",
      title: { pt: "Horários e venda de álcool em Lisboa", en: "Opening hours and alcohol sales in Lisbon" },
      what: { pt: "Desde 14 de fevereiro de 2026 é proibido em toda a cidade vender álcool para consumo fora do estabelecimento das 23h às 8h (domingo a quinta) e das 0h às 8h (sexta, sábado e vésperas de feriado). Consumir dentro ou em esplanada licenciada continua permitido. Coimas de 150 € a 3 000 €. O regulamento de horários está a ser revisto (consulta pública anunciada em julho de 2026).",
              en: "Since 14 February 2026, selling alcohol to drink outside the premises is banned citywide from 23:00 to 08:00 (Sunday to Thursday) and from 00:00 to 08:00 (Friday, Saturday and holiday eves). Drinking inside or on a licensed terrace is still allowed. Fines €150 to €3,000. The opening-hours regulation is being revised (public consultation announced July 2026)." },
      who: { pt: "Câmara; Polícia Municipal; PSP", en: "Câmara; Municipal Police; PSP" },
      without: { pt: "Coima de 150 € a 3 000 €", en: "A fine of €150 to €3,000" },
      sources: ["https://www.dn.pt/sociedade/proibio-de-venda-de-bebidas-alcolicas-para-consumo-no-exterior-em-lisboa-entra-hoje-em-vigor", "https://www.publico.pt/2026/05/16/local/noticia/bairro-alto-continua-copo-mao-apos-limitacao-venda-alcool-rua-2174949"] },
    { key: "rights",
      title: { pt: "Direitos de autor: SPA e PassMúsica", en: "Music rights: SPA and PassMúsica" },
      what: { pt: "Música protegida tocada em público, ao vivo ou gravada, precisa de autorização da SPA (autores): em eventos com bilhete, 5% da receita para a lotação total, com mínimos (tabela 2026); envia o alinhamento. Se tocares música gravada (DJ sets, vídeos), precisas também da licença PassMúsica (artistas e produtores, via GDA e Audiogest). Um concerto só ao vivo e sem gravações precisa da SPA mas não da PassMúsica.",
              en: "Protected music played in public, live or recorded, needs SPA authorisation (authors): at ticketed events, 5% of revenue for the full capacity, with minimums (2026 table); send the set list. If you play recorded music (DJ sets, videos), you also need a PassMúsica licence (performers and producers, via GDA and Audiogest). A live-only concert with no recordings needs SPA but not PassMúsica." },
      who: { pt: "SPA; PassMúsica (fiscalização: IGAC, ASAE, PSP/GNR)", en: "SPA; PassMúsica (inspection: IGAC, ASAE, PSP/GNR)" },
      cost: { pt: "Conforme as tabelas", en: "Per the tables" },
      without: { pt: "Pode ser crime de usurpação; pedir a licença depois da inspeção não resolve", en: "Can be the crime of «usurpação»; applying after an inspection doesn't fix it" },
      sources: ["https://www.spautores.pt/wp-content/uploads/2026/01/Tabela-Execucao-Publica-2026.pdf", "https://www.spautores.pt/faq-execucao-publica/"] },
    { key: "alcohol",
      title: { pt: "Álcool e comida no evento", en: "Alcohol and food at the event" },
      what: { pt: "É proibido vender ou dar álcool, mesmo gratuitamente, a menores de 18 anos: contraordenação muito grave, com perda dos lucros e possível interdição até 2 anos. Vender comida ou bebida num evento temporário normalmente exige mera comunicação prévia e, ao ar livre, licença de ocupação do espaço público.",
              en: "Selling or giving alcohol, even free, to under-18s is banned: a very serious offence, with loss of proceeds and a possible ban of up to 2 years. Selling food or drink at a temporary event normally needs a simple prior notice and, outdoors, a permit to occupy public space." },
      who: { pt: "ASAE; PSP; GNR", en: "ASAE; PSP; GNR" },
      uncertain: true,
      sources: ["https://www.dge.mec.pt/sites/default/files/Esaude/dl_106_2015_alcool.pdf", "https://diariodarepublica.pt/dre/detalhe/decreto-lei/50-2013-260432"] },
    { key: "fire",
      title: { pt: "Segurança contra incêndios e lotação", en: "Fire safety and capacity" },
      what: { pt: "O regime de segurança contra incêndios aplica-se também a recintos temporários; espetáculos são «utilização-tipo VI». A lotação segue os índices do regulamento técnico. Recintos pequenos (1.ª categoria de risco) são da competência da Câmara; os restantes, da ANEPC.",
              en: "The fire-safety regime also applies to temporary venues; shows are «use type VI». Capacity follows the technical regulation's occupancy rules. Small venues (risk category 1) are handled by the Câmara; others by ANEPC." },
      who: { pt: "Câmara (categoria 1); ANEPC; bombeiros", en: "Câmara (category 1); ANEPC; firefighters" },
      without: { pt: "Contraordenação e possível encerramento", en: "An offence and possible closure" },
      sources: ["https://diariodarepublica.pt/dr/legislacao-consolidada/portaria/2008-135056016", "https://diariodarepublica.pt/dr/legislacao-consolidada/portaria/2020-135640302"] },
    { key: "insurance",
      title: { pt: "Seguros", en: "Insurance" },
      what: { pt: "Obrigatórios: responsabilidade civil e acidentes pessoais para recintos improvisados (junto ao pedido de licença); seguro para voluntários numa organização com personalidade jurídica (a organização faz o seguro, o voluntário é o beneficiário); acidentes de trabalho para trabalhadores.",
              en: "Mandatory: civil liability and personal accident for temporary venues (with the licence application); insurance for volunteers in an organisation with legal personality (the organisation takes it out, the volunteer is covered); workplace-accident insurance for workers." },
      who: { pt: "Quem organiza", en: "The organiser" },
      uncertain: true,
      sources: ["https://diariodarepublica.pt/dr/detalhe/lei/71-1998-223016"] },
    { key: "foreign",
      title: { pt: "Pagar a artistas estrangeiros (não residentes)", en: "Paying foreign (non-resident) artists" },
      what: { pt: "O cachê de uma atuação em Portugal é rendimento português: quem paga retém 25% de IRS, a título definitivo. A maioria das convenções deixa Portugal tributar artistas, por isso o formulário 21-RFI normalmente não dispensa a retenção; o artista pede o crédito no seu país. Os serviços de artistas a promotores estão isentos de IVA.",
              en: "A fee for performing in Portugal is Portuguese income: the payer withholds a final 25% income tax. Most tax treaties let Portugal tax artists, so form 21-RFI usually doesn't waive it; the artist claims a credit at home. Artists' services to promoters are VAT-exempt." },
      who: { pt: "Quem paga; Autoridade Tributária", en: "The payer; the tax authority" },
      without: { pt: "Quem paga fica responsável pelo imposto não retido, com coimas", en: "The payer is liable for the tax not withheld, plus penalties" },
      sources: ["https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/informacoes_vinculativas/rendimento/DSRI/Documents/PIV_art%2017_cdt_espanha.pdf"] },
    { key: "resident",
      title: { pt: "Pagar a artistas residentes", en: "Paying resident artists" },
      what: { pt: "O artista passa fatura-recibo no Portal das Finanças. IVA isento (art. 9.º, n.º 15, quando o serviço é ao promotor, ou art. 53.º). Se tiveres contabilidade organizada, retém 23% de IRS, salvo «Sem retenção». Além disso, quem contrata paga 5,1% à Segurança Social e comunica os contratos de prestação de serviços à IGAC e à ACT.",
              en: "The artist issues an invoice-receipt on the tax portal. VAT-exempt (art. 9(15) when the service is to the promoter, or art. 53). If you have formal accounting, withhold 23% income tax, unless «Sem retenção». On top, whoever hires pays 5.1% to Social Security and notifies service contracts to IGAC and ACT." },
      who: { pt: "Quem contrata; Segurança Social; IGAC; ACT", en: "The hirer; Social Security; IGAC; ACT" },
      sources: ["https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs101b.aspx", "https://diariodarepublica.pt/dr/legislacao-consolidada/decreto-lei/2021-175043541"] }
]

// ── rights during an inspection ──
var RIGHTS = [
    { title: { pt: "Quem pode fiscalizar o quê", en: "Who can inspect what" },
      body: { pt: "PSP/GNR: crime, ordem pública, ruído, álcool a menores, licenças. Polícia Municipal: regras da Câmara (horários, licenças, ruído). ASAE: álcool, comida, recintos improvisados. IGAC: espetáculos, promotores, direitos de autor. Câmara/ANEPC/bombeiros: incêndios. Finanças: impostos. A polícia, ao identificar alguém, tem primeiro de se identificar e dizer o motivo; os inspetores têm cartão profissional.",
              en: "PSP/GNR: crime, public order, noise, alcohol to minors, licences. Municipal Police: council rules (hours, licences, noise). ASAE: alcohol, food, temporary venues. IGAC: shows, promoters, copyright. Câmara/ANEPC/firefighters: fire safety. Tax office: taxes. Police asking for ID must first identify themselves and give the reason; inspectors carry a professional card." },
      basis: "CPP art. 250.º, n.º 2; DL 276/2007 art. 17.º",
      sources: ["https://www.pgdlisboa.pt/leis/lei_mostra_articulado.php?artigo_id=199A0250&nid=199&tabela=leis"] },
    { title: { pt: "Entrada e buscas", en: "Entry and searches" },
      body: { pt: "Um espaço aberto ao público pode ser inspecionado durante o horário de funcionamento por quem tem competência, sem mandado (é fiscalização, não busca criminal). Uma busca num espaço reservado ou não acessível ao público precisa de ordem escrita de uma autoridade judiciária (juiz ou Ministério Público), salvo consentimento documentado, flagrante delito ou casos de crime violento com perigo iminente. Numa casa, só com ordem de juiz e entre as 7h e as 21h, com as exceções da lei.",
              en: "A place open to the public can be inspected during opening hours by whoever has the competence, without a warrant (it's an inspection, not a criminal search). A search of a private area, or one not open to the public, needs a written order from a judicial authority (judge or prosecutor), unless there's documented consent, a crime caught in the act, or violent crime with imminent danger. A home only with a judge's order and between 07:00 and 21:00, with the law's exceptions." },
      basis: "CPP arts. 174.º e 177.º; CRP art. 34.º",
      sources: ["https://www.pgdlisboa.pt/leis/lei_mostra_articulado.php?artigo_id=199A0174&nid=199&tabela=leis", "https://www.pgdlisboa.pt/leis/lei_mostra_articulado.php?artigo_id=199A0177&nid=199&tabela=leis"] },
    { title: { pt: "Identificação", en: "Identification" },
      body: { pt: "A polícia só pode identificar alguém num local público ou aberto ao público havendo suspeita fundada (crime, permanência irregular, mandado). Serve o cartão de cidadão, passaporte ou autorização de residência. Sem documento, pode ser levado ao posto pelo tempo estritamente necessário, nunca mais de seis horas, e tem sempre direito a contactar uma pessoa de confiança.",
              en: "Police may only identify someone in a public place or one open to the public on well-founded suspicion (a crime, irregular stay, a warrant). ID card, passport or residence permit all work. Without a document, a person can be taken to the station for the strictly necessary time, never more than six hours, and always has the right to contact someone they trust." },
      basis: "CPP art. 250.º",
      sources: ["https://www.pgdlisboa.pt/leis/lei_mostra_articulado.php?artigo_id=199A0250&nid=199&tabela=leis"] },
    { title: { pt: "Se fores constituído arguido", en: "If you're made a formal suspect (arguido)" },
      body: { pt: "Tens direito a saber os factos de que és suspeito, a não responder sobre eles, a escolher ou pedir advogado e a tê-lo presente em todos os atos, a falar com ele em privado se estiveres detido, a intérprete e a recorrer. Quem é detido tem de ser informado logo, de forma compreensível, das razões e dos seus direitos.",
              en: "You have the right to be told what you're suspected of, to refuse to answer about it, to choose or ask for a lawyer and have them present at every step, to speak to them privately if detained, to an interpreter, and to appeal. Anyone detained must be told at once, in a way they understand, why and what their rights are." },
      basis: "CPP art. 61.º; CRP art. 27.º, n.º 4",
      sources: ["https://www.pgdlisboa.pt/leis/lei_mostra_articulado.php?artigo_id=199A0061&nid=199&tabela=leis"] },
    { title: { pt: "Filmar a polícia", en: "Filming the police" },
      body: { pt: "Não há lei que proíba nem que autorize expressamente filmar agentes em serviço em público. Gravar para uso pessoal e como prova é provavelmente lícito; publicar imagens em que os agentes sejam identificáveis tem riscos (gravações ilícitas, direito à imagem). Confirma com um advogado antes de publicar.",
              en: "No law expressly bans or allows filming on-duty officers in public. Recording for personal use and as evidence is probably lawful; publishing footage where officers can be identified carries risk (unlawful recordings, image rights). Check with a lawyer before publishing." },
      basis: "CRP art. 37.º; Código Penal art. 199.º",
      uncertain: true, sources: [] },
    { title: { pt: "Como apresentar queixa", en: "How to complain" },
      body: { pt: "Sobre a atuação da PSP ou GNR: IGAI (queixa online em igai.pt, geral@igai.pt, 21 358 3430). Sobre qualquer serviço público: Provedor de Justiça (gratuito, sem advogado, provedor-jus.pt, 21 392 66 00). Um crime pode ser participado ao Ministério Público.",
              en: "About PSP or GNR conduct: IGAI (online complaint at igai.pt, geral@igai.pt, 21 358 3430). About any public service: the Ombudsman (free, no lawyer needed, provedor-jus.pt, 21 392 66 00). A crime can be reported to the public prosecutor." },
      sources: ["https://www.igai.pt/", "https://www.provedor-jus.pt/"] },
    { title: { pt: "A Constituição", en: "The Constitution" },
      body: { pt: "Art. 26.º: imagem e reserva da vida privada. Art. 34.º: inviolabilidade do domicílio. Art. 37.º: liberdade de expressão e de informação, sem censura. Art. 45.º: direito de reunião pacífica e sem armas, mesmo em lugares públicos, sem autorização. Art. 73.º e 78.º: direito à cultura, à fruição e à criação cultural.",
              en: "Art. 26: image and privacy. Art. 34: the home is inviolable. Art. 37: freedom of expression and information, no censorship. Art. 45: the right to assemble peacefully and unarmed, even in public places, without authorisation. Arts. 73 and 78: the right to culture, to enjoy and create it." },
      sources: ["https://www.parlamento.pt/Legislacao/Paginas/ConstituicaoRepublicaPortuguesa.aspx"] }
]

// ── help now ──
var HELP = [
    { name: "112", number: "112", urgent: true, what: { pt: "Emergência: ambulância, bombeiros, polícia.", en: "Emergency: ambulance, firefighters, police." } },
    { name: "SNS 24", number: "808 24 24 24", top: true, what: { pt: "Saúde, 24 horas; opção 4 para apoio psicológico.", en: "Health advice, 24/7; option 4 for psychological support." } },
    { name: "Linha 1411", number: "1411", top: true, what: { pt: "Prevenção do suicídio e apoio psicológico, gratuita, 24 horas.", en: "Suicide prevention and psychological support, free, 24/7." } },
    { name: "Kosmicare", number: "Rua Cesário Verde 17B", what: { pt: "Redução de riscos e análise de substâncias, anónima (Arroios). Horários a confirmar.", en: "Harm reduction and anonymous drug checking (Arroios). Hours to confirm." }, url: "https://www.timeout.pt/lisboa/pt/noite/kosmicare-os-guardioes-das-festas" },
    { name: "APAV", number: "116 006", top: true, what: { pt: "Apoio à vítima, gratuito, dias úteis 8h–23h.", en: "Victim support, free, weekdays 08:00–23:00." } },
    { name: "Linha de Emergência Social", number: "144", what: { pt: "Emergência social, gratuita, 24 horas.", en: "Social emergency line, free, 24/7." } },
    { name: "SOS Voz Amiga", number: "213 544 545", what: { pt: "Escuta, cerca das 15h30 à 0h30.", en: "Listening line, about 15:30–00:30." } },
    { name: "IGAI", number: "21 358 3430", what: { pt: "Queixas sobre a atuação da PSP e GNR.", en: "Complaints about PSP and GNR conduct." }, url: "https://www.igai.pt/" },
    { name: "Provedor de Justiça", number: "21 392 66 00", what: { pt: "Queixas sobre serviços públicos, gratuito.", en: "Complaints about public services, free." }, url: "https://www.provedor-jus.pt/" }
]

// ── the one-page door sheet ──
var DOOR_SHEET = {
    pt: "FOLHA DA PORTA · numa inspeção\n\n1. Calma e educação. Pede a identificação e o motivo da visita.\n2. Chama a pessoa responsável pelo evento.\n3. Tem à mão: registo IGAC / comunicação do espetáculo, licença de recinto, licença de ruído, SPA/PassMúsica, seguros, lotação.\n4. Num espaço aberto ao público, a fiscalização pode entrar no horário de funcionamento. Uma busca a uma zona reservada precisa de ordem de autoridade judiciária (salvo consentimento ou flagrante delito).\n5. Identificação: cartão de cidadão, passaporte ou título de residência. Sem documento: no máximo 6 horas no posto e direito a contactar alguém.\n6. Se fores constituído arguido: podes não responder e pedir advogado.\n7. Anota quem veio, a hora, o que verificaram e o resultado. Pede cópia de qualquer auto.\n8. Emergência: 112. Queixa: IGAI (21 358 3430) ou Provedor de Justiça (21 392 66 00).\n\nInformação jurídica, não aconselhamento. Verificado a 2026-11-25.",
    en: "DOOR SHEET · during an inspection\n\n1. Stay calm and polite. Ask for their ID and the reason for the visit.\n2. Call the person in charge of the event.\n3. Have at hand: IGAC registration / show notice, venue licence, noise licence, SPA/PassMúsica, insurance, capacity.\n4. In a place open to the public, inspectors may enter during opening hours. Searching a private area needs a judicial authority's order (unless there's consent or a crime caught in the act).\n5. ID: citizen card, passport or residence permit. Without one: at most 6 hours at the station and the right to contact someone.\n6. If you're made an arguido (formal suspect): you may refuse to answer and ask for a lawyer.\n7. Note who came, the time, what they checked and the outcome. Ask for a copy of any report.\n8. Emergency: 112. Complaints: IGAI (21 358 3430) or the Ombudsman (21 392 66 00).\n\nLegal information, not advice. Checked 2026-11-25."
}

// Rows the Production plan's Licences table starts with (the papers most events need).
var LICENCE_ROWS = [
    { pt: "Registo de promotor / comunicação do espetáculo (IGAC)", en: "Promoter registration / show notice (IGAC)" },
    { pt: "Licença de recinto improvisado (se não for um espaço licenciado)", en: "Temporary venue licence (if not a licensed venue)" },
    { pt: "Licença especial de ruído (se aplicável)", en: "Special noise licence (if needed)" },
    { pt: "SPA (autores) e PassMúsica (música gravada)", en: "SPA (authors) and PassMúsica (recorded music)" },
    { pt: "Seguros: responsabilidade civil, acidentes pessoais, voluntários", en: "Insurance: liability, personal accident, volunteers" }
]
