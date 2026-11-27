-- ==========================================
-- 0. REMOÇÃO DE TABELAS EXISTENTES (CASO NECESSÁRIO)
-- ==========================================
DROP TABLE IF EXISTS historico_status_reembolso CASCADE;
DROP TABLE IF EXISTS solicitacao_reembolso CASCADE;
DROP TABLE IF EXISTS despesa_viagem CASCADE;
DROP TABLE IF EXISTS checklist_bagagem CASCADE;
DROP TABLE IF EXISTS avaliacao_estabelecimento CASCADE;
DROP TABLE IF EXISTS estabelecimento_favorito CASCADE;
DROP TABLE IF EXISTS viagem CASCADE;
DROP TABLE IF EXISTS item_bagagem_catalogo CASCADE;
DROP TABLE IF EXISTS estabelecimento CASCADE;
DROP TABLE IF EXISTS usuario CASCADE;

-- Remoção dos ENUMs caso já existam
DROP TYPE IF EXISTS categoria_despesa_enum;
DROP TYPE IF EXISTS status_reembolso_enum;
DROP TYPE IF EXISTS tipo_viagem_enum;
DROP TYPE IF EXISTS faixa_preco_enum;
DROP TYPE IF EXISTS categoria_estabelecimento_enum;
DROP TYPE IF EXISTS tipo_perfil_user;

-- ==========================================
-- CRIAÇÃO DOS TIPOS ENUM
-- ==========================================
CREATE TYPE tipo_perfil_user AS ENUM ('VIAJANTE', 'MODERADOR', 'ADMIN');
CREATE TYPE categoria_estabelecimento_enum AS ENUM ('RESTAURANTE', 'HOTEL', 'HOSTEL', 'PONTO_TURISTICO', 'TRANSPORTE', 'LOJA');
CREATE TYPE faixa_preco_enum AS ENUM ('ECONOMICO', 'MODERADO', 'ALTO', 'LUXO');
CREATE TYPE tipo_viagem_enum AS ENUM ('LAZER', 'NEGOCIOS', 'MOCHILAO', 'INTERCAMBIO', 'FAMILIA');
CREATE TYPE status_reembolso_enum AS ENUM ('PENDENTE', 'EM_ANALISE', 'APROVADO', 'REJEITADO', 'PAGO');
CREATE TYPE categoria_despesa_enum AS ENUM ('ALIMENTACAO', 'HOSPEDAGEM', 'TRANSPORTE', 'PASSEIOS', 'COMPRAS', 'EMERGENCIA');

-- ==========================================
-- 1. TABELA: usuario
-- ==========================================
CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    data_nascimento DATE NOT NULL,
    eh_maior_idade BOOLEAN NOT NULL,
    fk_usuario INT,
    tipo_perfil tipo_perfil_user NOT NULL,
    consentimento_lgpd_geo BOOLEAN NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_usuario_email UNIQUE (email),
    CONSTRAINT fk_usuario_responsavel FOREIGN KEY (fk_usuario) REFERENCES usuario(id_usuario) ON DELETE SET NULL
);

-- ==========================================
-- 2. TABELA: estabelecimento
-- ==========================================
CREATE TABLE estabelecimento (
    id_estabelecimento SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    categoria categoria_estabelecimento_enum NOT NULL,
    faixa_preco faixa_preco_enum NOT NULL,
    avaliacao_media DECIMAL(3,2),
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    horario_abertura TIME,
    horario_fechamento TIME,
    ativo BOOLEAN DEFAULT TRUE
);

-- ==========================================
-- 3. TABELA: item_bagagem_catalogo
-- ==========================================
CREATE TABLE item_bagagem_catalogo (
    id_item_bagagem_catalogo SERIAL PRIMARY KEY,
    nome_item VARCHAR(100) NOT NULL,
    perfil_viagem tipo_viagem_enum,
    clima_indicado VARCHAR(30)
);

-- ==========================================
-- 4. TABELA: viagem
-- ==========================================
CREATE TABLE viagem (
    id_viagem SERIAL PRIMARY KEY,
    fk_usuario INT NOT NULL,
    titulo_viagem VARCHAR(120) NOT NULL,
    tipo_viagem tipo_viagem_enum NOT NULL,
    destino_cidade VARCHAR(100) NOT NULL,
    destino_pais VARCHAR(100) NOT NULL,
    fuso_horario_destino VARCHAR(50) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    orcamento_total DECIMAL(12,2) NOT NULL,
    ativa BOOLEAN DEFAULT TRUE,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_viagem_usuario FOREIGN KEY (fk_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE
);

-- ==========================================
-- 5. TABELA: estabelecimento_favorito
-- ==========================================
CREATE TABLE estabelecimento_favorito (
    id_estabelecimento_favorito SERIAL PRIMARY KEY,
    fk_usuario INT NOT NULL,
    fk_estabelecimento INT NOT NULL,
    data_adicao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_estabelecimento_favorito_usuario FOREIGN KEY (fk_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_estabelecimento_favorito_estabelecimento FOREIGN KEY (fk_estabelecimento) REFERENCES estabelecimento(id_estabelecimento) ON DELETE CASCADE
);

-- ==========================================
-- 6. TABELA: avaliacao_estabelecimento
-- ==========================================
CREATE TABLE avaliacao_estabelecimento (
    id_avaliacao_estabelecimento SERIAL PRIMARY KEY,
    fk_estabelecimento INT NOT NULL,
    fk_usuario INT NOT NULL,
    fk_viagem INT NOT NULL,
    nota INT NOT NULL,
    comentario TEXT,
    data_avaliacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_avaliacao_estabelecimento_estabelecimento FOREIGN KEY (fk_estabelecimento) REFERENCES estabelecimento(id_estabelecimento) ON DELETE CASCADE,
    CONSTRAINT fk_avaliacao_estabelecimento_usuario FOREIGN KEY (fk_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_avaliacao_estabelecimento_viagem FOREIGN KEY (fk_viagem) REFERENCES viagem(id_viagem) ON DELETE CASCADE
);

-- ==========================================
-- 7. TABELA: checklist_bagagem
-- ==========================================
CREATE TABLE checklist_bagagem (
    id_checklist_bagagem SERIAL PRIMARY KEY,
    fk_viagem INT NOT NULL,
    nome_item VARCHAR(100) NOT NULL,
    item_checado BOOLEAN DEFAULT FALSE,
    incluso_manualmente BOOLEAN DEFAULT FALSE,

    CONSTRAINT fk_checklist_bagagem_viagem FOREIGN KEY (fk_viagem) REFERENCES viagem(id_viagem) ON DELETE CASCADE
);

-- ==========================================
-- 8. TABELA: despesa_viagem
-- ==========================================
CREATE TABLE despesa_viagem (
    id_despesa_viagem SERIAL PRIMARY KEY,
    fk_viagem INT NOT NULL,
    categoria categoria_despesa_enum NOT NULL,
    descricao VARCHAR(150) NOT NULL,
    valor_despesa DECIMAL(10,2) NOT NULL,
    data_despesa TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_despesa_viagem_viagem FOREIGN KEY (fk_viagem) REFERENCES viagem(id_viagem) ON DELETE CASCADE
);

-- ==========================================
-- 9. TABELA: solicitacao_reembolso
-- ==========================================
CREATE TABLE solicitacao_reembolso (
    id_solicitacao_reembolso SERIAL PRIMARY KEY,
    fk_viagem INT NOT NULL,
    fk_usuario_solicitante INT NOT NULL,
    descricao_incidente TEXT NOT NULL,
    valor_total_pleiteado DECIMAL(10,2) NOT NULL,
    url_comprovante_anexo VARCHAR(255) NOT NULL,
    status status_reembolso_enum NOT NULL,
    fk_usuario_moderador INT,
    data_solicitacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_solicitacao_reembolso_viagem FOREIGN KEY (fk_viagem) REFERENCES viagem(id_viagem) ON DELETE CASCADE,
    CONSTRAINT fk_solicitacao_reembolso_solicitante FOREIGN KEY (fk_usuario_solicitante) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_solicitacao_reembolso_moderador FOREIGN KEY (fk_usuario_moderador) REFERENCES usuario(id_usuario) ON DELETE SET NULL
);

-- ==========================================
-- 10. TABELA: historico_status_reembolso
-- ==========================================
CREATE TABLE historico_status_reembolso (
    id_historico_status_reembolso SERIAL PRIMARY KEY,
    fk_solicitacao_reembolso INT NOT NULL,
    status_anterior status_reembolso_enum,
    status_novo status_reembolso_enum NOT NULL,
    observacao_moderador TEXT,
    fk_usuario INT NOT NULL,
    data_modificacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_historico_status_reembolso_solicitacao FOREIGN KEY (fk_solicitacao_reembolso) REFERENCES solicitacao_reembolso(id_solicitacao_reembolso) ON DELETE CASCADE,
    CONSTRAINT fk_historico_status_reembolso_usuario FOREIGN KEY (fk_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE
);


-- ==========================================
-- SCRIPT DE INSERÇÃO DIDÁTICA (DADOS REALISTAS)
-- ==========================================

-- 1. USUARIO
INSERT INTO usuario (nome, email, senha_hash, data_nascimento, eh_maior_idade, fk_usuario, tipo_perfil, consentimento_lgpd_geo) VALUES
('Ana Souza', 'ana.admin@sleepstreet.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '1988-04-12', TRUE, NULL, 'ADMIN', TRUE),
('Carlos Silva', 'carlos.mod@sleepstreet.com', '$2y$10$8kR5vN2m1L0p9Q3w5e6r7u8i9o0p1a2s3d4f5g6h7j8k9l0z1x2c3v', '1985-09-23', TRUE, NULL, 'MODERADOR', TRUE),
('Beatriz Lima', 'beatriz.lima@email.com', '$2y$10$3vB2nM1k9L8j7H6g5f4d3s2a1p0o9i8u7y6t5r4e3w2q1z0x9c8v7b', '1995-07-15', TRUE, NULL, 'VIAJANTE', TRUE),
('Daniel Oliveira', 'daniel.oli@email.com', '$2y$10$5tG7bN4m2V1c0x9z8l7k6j5h4g3f2d1s0a9p8o7i6u5y4t3r2e1w0q', '1980-11-30', TRUE, NULL, 'VIAJANTE', TRUE),
('Elena Rocha', 'elena.rocha@email.com', '$2y$10$1qA2z3W4s5X6c7D8f9V0gHjKlPoIuYtReWqAsDfGhJkLzXcVbNm', '2010-02-18', FALSE, 4, 'VIAJANTE', TRUE),
('Felipe Santos', 'felipe.santos@email.com', '$2y$10$9p0O9i8U7y6T5r4E3w2Q1a0S9d8F7g6H5j4K3l2Z1x0C9v8B7n6M5', '1998-06-05', TRUE, NULL, 'VIAJANTE', TRUE),
('Gabriela Costa', 'gabriela.mod@sleepstreet.com', '$2y$10$4bN5m6L7k8J9h0G1f2D3s4A5p6O7i8U9y0T1r2E3w4Q5a6S7d8F9g', '1990-12-09', TRUE, NULL, 'MODERADOR', TRUE),
('Hugo Almeida', 'hugo.almeida@email.com', '$2y$10$7z8x9c0v1b2n3m4L5k6J7h8G9f0D1s2A3p4O5i6U7y8T9r0E1w2Q3', '1992-03-27', TRUE, NULL, 'VIAJANTE', TRUE),
('Isabela Martins', 'isabela.martins@email.com', '$2y$10$2w3e4r5t6y7u8i9o0p1a2s3d4f5g6h7j8k9l0z1x2c3v4b5n6m7k8', '2009-08-14', FALSE, 3, 'VIAJANTE', TRUE),
('João Pereira', 'joao.pereira@email.com', '$2y$10$6m5n4b3v2c1x0z9l8k7j6h5g4f3d2s1a0p9o8i7u6y5t4r3e2w1q0', '1994-10-02', TRUE, NULL, 'VIAJANTE', TRUE);

-- 2. ESTABELECIMENTO
INSERT INTO estabelecimento (nome, categoria, faixa_preco, avaliacao_media, latitude, longitude, horario_abertura, horario_fechamento, ativo) VALUES
('Hostel Central Curitiba', 'HOSTEL', 'ECONOMICO', 4.65, -25.42840000, -49.27330000, '00:00:00', '23:59:59', TRUE),
('Bistrô Rua das Flores', 'RESTAURANTE', 'MODERADO', 4.80, -25.43120000, -49.27150000, '11:30:00', '23:00:00', TRUE),
('Hotel Grand Batel', 'HOTEL', 'LUXO', 4.90, -25.44190000, -49.28950000, '00:00:00', '23:59:59', TRUE),
('Museu Oscar Niemeyer', 'PONTO_TURISTICO', 'ECONOMICO', 4.85, -25.41020000, -49.26710000, '10:00:00', '18:00:00', TRUE),
('Estação Rodoferroviária Central', 'TRANSPORTE', 'ECONOMICO', 4.10, -25.43680000, -49.25720000, '00:00:00', '23:59:59', TRUE),
('Empório do Viajante', 'LOJA', 'MODERADO', 4.50, -25.42500000, -49.27800000, '09:00:00', '20:00:00', TRUE),
('Pousada Serra Verde', 'HOTEL', 'MODERADO', 4.70, -25.45100000, -49.28100000, '00:00:00', '23:59:59', TRUE),
('Cantina Italiana Santa Felicidade', 'RESTAURANTE', 'ALTO', 4.75, -25.40150000, -49.33210000, '11:30:00', '23:30:00', TRUE),
('Jardim Botânico Municipal', 'PONTO_TURISTICO', 'ECONOMICO', 4.95, -25.44290000, -49.23850000, '06:00:00', '19:30:00', TRUE),
('Albergue Mochileiro Urbano', 'HOSTEL', 'ECONOMICO', 4.30, -25.42950000, -49.26900000, '07:00:00', '23:00:00', TRUE);

-- 3. ITEM_BAGAGEM_CATALOGO
INSERT INTO item_bagagem_catalogo (nome_item, perfil_viagem, clima_indicado) VALUES
('Passaporte e Documentos Pessoais', 'INTERCAMBIO', 'TODOS'),
('Adaptador Universal de Tomada', 'NEGOCIOS', 'TODOS'),
('Casaco Impermeável Corta-Vento', 'MOCHILAO', 'FRIO'),
('Protetor Solar FPS 50', 'LAZER', 'QUENTE'),
('Mochila Cargueira 50L', 'MOCHILAO', 'TODOS'),
('Kit Primeiros Socorros Básico', 'FAMILIA', 'TODOS'),
('Notebook e Carregador', 'NEGOCIOS', 'TODOS'),
('Tênis de Caminhada Confortável', 'MOCHILAO', 'AMENO'),
('Power Bank 20000mAh', 'INTERCAMBIO', 'TODOS'),
('Garrafa Térmica Reutilizável', 'LAZER', 'QUENTE');

-- 4. VIAGEM
INSERT INTO viagem (fk_usuario, titulo_viagem, tipo_viagem, destino_cidade, destino_pais, fuso_horario_destino, data_inicio, data_fim, orcamento_total, ativa) VALUES
(3, 'Mochilão Sul do Brasil', 'MOCHILAO', 'Curitiba', 'Brasil', 'America/Sao_Paulo', '2026-12-01', '2026-12-10', 3500.00, TRUE),
(4, 'Férias em Família na Serra', 'FAMILIA', 'Gramado', 'Brasil', 'America/Sao_Paulo', '2026-12-15', '2026-12-22', 8000.00, TRUE),
(6, 'Congresso Internacional de Tecnologia', 'NEGOCIOS', 'Lisboa', 'Portugal', 'Europe/Lisbon', '2027-01-10', '2027-01-16', 12000.00, TRUE),
(8, 'Roteiro Cultural Buenos Aires', 'LAZER', 'Buenos Aires', 'Argentina', 'America/Argentina/Buenos_Aires', '2026-11-25', '2026-12-02', 4500.00, TRUE),
(10, 'Intercâmbio de Idiomas Dublin', 'INTERCAMBIO', 'Dublin', 'Irlanda', 'Europe/Dublin', '2027-02-01', '2027-03-01', 18000.00, TRUE),
(3, 'Fim de Semana no Litoral', 'LAZER', 'Florianópolis', 'Brasil', 'America/Sao_Paulo', '2026-10-10', '2026-10-13', 1800.00, FALSE),
(4, 'Reunião Executiva São Paulo', 'NEGOCIOS', 'São Paulo', 'Brasil', 'America/Sao_Paulo', '2026-11-05', '2026-11-07', 2500.00, FALSE),
(6, 'Trilha Patagônia Argentina', 'MOCHILAO', 'El Chaltén', 'Argentina', 'America/Argentina/Buenos_Aires', '2027-03-10', '2027-03-20', 7500.00, TRUE),
(8, 'Tour Gastronômico Santiago', 'LAZER', 'Santiago', 'Chile', 'America/Santiago', '2026-12-18', '2026-12-24', 5200.00, TRUE),
(10, 'Viagem de Estudos Madrid', 'INTERCAMBIO', 'Madrid', 'Espanha', 'Europe/Madrid', '2027-04-05', '2027-04-20', 14000.00, TRUE);

-- 5. ESTABELECIMENTO_FAVORITO
INSERT INTO estabelecimento_favorito (fk_usuario, fk_estabelecimento) VALUES
(3, 1),
(3, 4),
(4, 3),
(4, 8),
(6, 2),
(6, 5),
(8, 9),
(8, 10),
(10, 6),
(10, 7);

-- 6. AVALIACAO_ESTABELECIMENTO
INSERT INTO avaliacao_estabelecimento (fk_estabelecimento, fk_usuario, fk_viagem, nota, comentario) VALUES
(1, 3, 1, 5, 'Excelente localização, equipe muito acolhedora e quartos limpos.'),
(4, 3, 1, 5, 'Arquitetura incrível e exposições muito bem organizadas.'),
(3, 4, 2, 5, 'Conforto impecável e café da manhã excepcional para toda a família.'),
(8, 4, 2, 4, 'Comida deliciosa e porções generosas, apenas um pouco cheio no jantar.'),
(2, 6, 3, 5, 'Ambiente tranquilo ideal para reuniões rápidas e ótima gastronomia.'),
(5, 6, 3, 4, 'Bem sinalizado e fácil acesso ao transporte público.'),
(9, 8, 4, 5, 'Lugar maravilhoso para caminhar e tirar fotos no fim de tarde.'),
(10, 8, 4, 4, 'Ótimo custo-benefício para quem viaja sozinho.'),
(6, 10, 5, 5, 'Encontrei todos os acessórios de viagem que precisava.'),
(7, 10, 5, 5, 'Atendimento cordial e ambiente muito silencioso para descansar.');

-- 7. CHECKLIST_BAGAGEM
INSERT INTO checklist_bagagem (fk_viagem, nome_item, item_checado, incluso_manualmente) VALUES
(1, 'Mochila Cargueira 50L', TRUE, FALSE),
(1, 'Casaco Impermeável Corta-Vento', TRUE, FALSE),
(1, 'Cadeado para Locker de Hostel', FALSE, TRUE),
(2, 'Kit Primeiros Socorros Básico', TRUE, FALSE),
(2, 'Documentos das Crianças', TRUE, TRUE),
(3, 'Notebook e Carregador', TRUE, FALSE),
(3, 'Adaptador Universal de Tomada', TRUE, FALSE),
(4, 'Tênis de Caminhada Confortável', TRUE, FALSE),
(5, 'Passaporte e Documentos Pessoais', TRUE, FALSE),
(5, 'Power Bank 20000mAh', FALSE, FALSE);

-- 8. DESPESA_VIAGEM
INSERT INTO despesa_viagem (fk_viagem, categoria, descricao, valor_despesa) VALUES
(1, 'HOSPEDAGEM', '3 diárias no Hostel Central Curitiba', 240.00),
(1, 'ALIMENTACAO', 'Almoço executivo no centro histórico', 48.50),
(2, 'HOSPEDAGEM', 'Pacote 5 diárias Hotel Grand Batel', 3200.00),
(2, 'PASSEIOS', 'Ingressos parque temático família', 650.00),
(3, 'TRANSPORTE', 'Passagem aérea ida e volta Lisboa', 4800.00),
(3, 'ALIMENTACAO', 'Jantar de negócios Bistrô', 185.00),
(4, 'TRANSPORTE', 'Cartão transporte metrô e ônibus', 60.00),
(4, 'COMPRAS', 'Lembranças e artesanato local', 120.00),
(5, 'HOSPEDAGEM', 'Acomodação estudantil primeiro mês', 3900.00),
(5, 'EMERGENCIA', 'Compra de medicamentos na farmácia', 95.00);

-- 9. SOLICITACAO_REEMBOLSO
INSERT INTO solicitacao_reembolso (fk_viagem, fk_usuario_solicitante, descricao_incidente, valor_total_pleiteado, url_comprovante_anexo, status, fk_usuario_moderador) VALUES
(1, 3, 'Cobrança duplicada na reserva do hostel parceiro.', 240.00, 'https://cdn.sleepstreet.com/docs/comp_001.pdf', 'APROVADO', 2),
(2, 4, 'Cancelamento de passeio devido a condições climáticas extremas.', 650.00, 'https://cdn.sleepstreet.com/docs/comp_002.pdf', 'EM_ANALISE', 7),
(3, 6, 'Atraso superior a 6 horas no voo conexo com necessidade de alimentação.', 185.00, 'https://cdn.sleepstreet.com/docs/comp_003.pdf', 'PAGO', 2),
(4, 8, 'Estabelecimento fechado no horário agendado pelo aplicativo.', 120.00, 'https://cdn.sleepstreet.com/docs/comp_004.pdf', 'PENDENTE', NULL),
(5, 10, 'Taxa extra cobrada indevidamente no check-in da acomodação.', 350.00, 'https://cdn.sleepstreet.com/docs/comp_005.pdf', 'APROVADO', 7),
(6, 3, 'Solicitação fora do prazo regulamentar de 30 dias após viagem.', 150.00, 'https://cdn.sleepstreet.com/docs/comp_006.pdf', 'REJEITADO', 2),
(7, 4, 'Reembolso de traslado cancelado pelo motorista parceiro.', 95.00, 'https://cdn.sleepstreet.com/docs/comp_007.pdf', 'PAGO', 7),
(8, 6, 'Equipamento alugado com defeito na trilha.', 210.00, 'https://cdn.sleepstreet.com/docs/comp_008.pdf', 'EM_ANALISE', 2),
(9, 8, 'Divergência no valor cobrado pelo ingresso turístico.', 80.00, 'https://cdn.sleepstreet.com/docs/comp_009.pdf', 'PENDENTE', NULL),
(10, 10, 'Despesa médica emergencial coberta pelo seguro viagem.', 420.00, 'https://cdn.sleepstreet.com/docs/comp_010.pdf', 'APROVADO', 7);

-- 10. HISTORICO_STATUS_REEMBOLSO
INSERT INTO historico_status_reembolso (fk_solicitacao_reembolso, status_anterior, status_novo, observacao_moderador, fk_usuario) VALUES
(1, 'PENDENTE', 'EM_ANALISE', 'Documentação fiscal recebida e em verificação.', 2),
(1, 'EM_ANALISE', 'APROVADO', 'Comprovante de cobrança duplicada validado com o estabelecimento.', 2),
(2, 'PENDENTE', 'EM_ANALISE', 'Aguardando confirmação meteorológica oficial da operadora.', 7),
(3, 'PENDENTE', 'APROVADO', 'Declaração de atraso da companhia aérea validada.', 2),
(3, 'APROVADO', 'PAGO', 'Transferência realizada via PIX para o solicitante.', 2),
(5, 'PENDENTE', 'APROVADO', 'Estabelecimento confirmou erro na cobrança de taxa.', 7),
(6, 'PENDENTE', 'REJEITADO', 'Prazo máximo de solicitação expirado conforme termos de uso.', 2),
(7, 'PENDENTE', 'APROVADO', 'Cancelamento unilateral confirmado pelo sistema.', 7),
(7, 'APROVADO', 'PAGO', 'Reembolso creditado na conta cadastrada.', 7),
(10, 'PENDENTE', 'APROVADO', 'Nota fiscal hospitalar conferida e aprovada.', 7);


-- ==========================================
-- 11. CONSULTAS DE VALIDAÇÃO (TESTE RÁPIDO)
-- ==========================================

-- 1. Testar tabela usuario
SELECT * FROM usuario;

-- 2. Testar tabela estabelecimento
SELECT * FROM estabelecimento;

-- 3. Testar tabela item_bagagem_catalogo
SELECT * FROM item_bagagem_catalogo;

-- 4. Testar tabela viagem
SELECT * FROM viagem;

-- 5. Testar tabela estabelecimento_favorito
SELECT * FROM estabelecimento_favorito;

-- 6. Testar tabela avaliacao_estabelecimento
SELECT * FROM avaliacao_estabelecimento;

-- 7. Testar tabela checklist_bagagem
SELECT * FROM checklist_bagagem;

-- 8. Testar tabela despesa_viagem
SELECT * FROM despesa_viagem;

-- 9. Testar tabela solicitacao_reembolso
SELECT * FROM solicitacao_reembolso;

-- 10. Testar tabela historico_status_reembolso
SELECT * FROM historico_status_reembolso;

-- Questao Numero 3
-- Consulte o título da viagem, a cidade de destino, o país de destino e o nome do
-- viajante para todas as viagens que estão ativas (ativa = TRUE) com destino fora do 'Brasil',
-- ordenadas pelo título da viagem em ordem alfabética.

SELECT  
    viagem.titulo_viagem,
    viagem.destino_cidade,
    viagem.destino_pais,
    u.nome
FROM usuario u
INNER JOIN viagem
    ON viagem.fk_usuario = u.id_usuario
WHERE viagem.ativa = TRUE
ORDER BY u.nome ASC;

