# frozen_string_literal: true

require './config/database.rb'

class Application
  def self.migrate_up
    migrate_up!
  end

  def self.migrate_down
    migrate_down!
  end

  def self.import_from_base
    MODEL_CLASSES.each do |model_class|
      puts "\n[#{model_class}] importing from base"
      model_class.import_from_log
    end
  end

  def self.import_from_delta
    MODEL_CLASSES.each do |model_class|
      puts "\n[#{model_class}] importing from delta"
      model_class.import_from_delta
    end
  end

  def self.dump
    raise NotImplementedError, 'Dump is only supported with SQLite3, but [' + get_adapter + '] adapter is being used.' if get_adapter != 'sqlite3'

    system "echo '.dump ceps' | sqlite3 ./db/database.sqlite3 > db/ceps.sql"
  end

  def self.join
    if get_adapter == 'postgres'
      DataMapper.repository(:default).adapter.execute 'DELETE FROM zips'
      DataMapper.repository(:default).adapter.execute "
  		INSERT INTO zips
  		  SELECT  RS.CEP AS CEP,
  				  RS.ENDERECO AS ENDERECO,
  				  RS.BAIRRO AS BAIRRO,
  				  RS.CIDADE AS CIDADE,
  				  RS.UF AS ESTADO,
  				  CASE RS.UF
  				  WHEN 'AC' THEN 'Acre'
  				  WHEN 'AL' THEN 'Alagoas'
  				  WHEN 'AP' THEN 'Amapá'
  				  WHEN 'AM' THEN 'Amazonas'
  				  WHEN 'BA' THEN 'Bahia'
  				  WHEN 'CE' THEN 'Ceará'
  				  WHEN 'DF' THEN 'Distrito Federal'
  				  WHEN 'ES' THEN 'Espírito Santo'
  				  WHEN 'GO' THEN 'Goiás'
  				  WHEN 'MA' THEN 'Maranhão'
  				  WHEN 'MT' THEN 'Mato Grosso'
  				  WHEN 'MS' THEN 'Mato Grosso do Sul'
  				  WHEN 'MG' THEN 'Minas Gerais'
  				  WHEN 'PA' THEN 'Pará'
  				  WHEN 'PB' THEN 'Paraíba'
  				  WHEN 'PR' THEN 'Paraná'
  				  WHEN 'PE' THEN 'Pernambuco'
  				  WHEN 'PI' THEN 'Piauí'
  				  WHEN 'RJ' THEN 'Rio de Janeiro'
  				  WHEN 'RN' THEN 'Rio Grande do Norte'
  				  WHEN 'RS' THEN 'Rio Grande do Sul'
  				  WHEN 'RO' THEN 'Rondônia'
  				  WHEN 'RR' THEN 'Rorâima'
  				  WHEN 'SC' THEN 'Santa Catarina'
  				  WHEN 'SP' THEN 'São Paulo'
  				  WHEN 'SE' THEN 'Sergipe'
  				  WHEN 'TO' THEN 'Tocantins'
  				  END AS NOME_ESTADO
  		  FROM (
  					SELECT  COALESCE(log.CEP, loc.CEP) AS CEP,
  							CASE log.LOG_STA_TLO
  							WHEN 'S' THEN
  							  COALESCE(log.TLO_TX, '') || ' ' || COALESCE(log.LOG_NO, '')
  							ELSE
  							  COALESCE(log.LOG_NO, '')
  							END ENDERECO,
  							COALESCE(bai.BAI_NO, '')   AS BAIRRO,
  							loc.LOC_NO               AS CIDADE,
  							loc.UFE_SG               AS UF
  					FROM localidades loc
  					LEFT JOIN logradouros log ON log.LOC_NU = loc.LOC_NU
  					LEFT JOIN bairros bai     ON log.BAI_NU_INI = bai.BAI_NU

  					UNION ALL

  					SELECT  uni.CEP                  AS CEP,
  							uni.UOP_ENDERECO         AS ENDERECO,
  							COALESCE(bai.BAI_NO, '')   AS BAIRRO,
  							loc.LOC_NO               AS CIDADE,
  							uni.UFE_SG               AS UF
  					FROM unidade_operacionals uni
  					LEFT JOIN bairros bai     ON uni.BAI_NU = bai.BAI_NU
  					LEFT JOIN localidades loc ON bai.LOC_NU = loc.LOC_NU

  					UNION ALL

  					SELECT  gra.CEP                  AS CEP,
  							gra.GRU_ENDERECO         AS ENDERECO,
  							COALESCE(bai.BAI_NO, '')   AS BAIRRO,
  							loc.LOC_NO               AS CIDADE,
  							gra.UFE_SG               AS UF
  					FROM grande_usuarios gra
  					LEFT JOIN bairros bai     ON gra.BAI_NU = bai.BAI_NU
  					LEFT JOIN localidades loc ON bai.LOC_NU = loc.LOC_NU
  		  ) RS
  		  WHERE RS.CEP <> ''"
    else
      Bairro.transaction do |_t|
        DataMapper.repository(:default).adapter.execute 'CREATE TABLE zips_new like zips'
        DataMapper.repository(:default).adapter.execute "
     	      INSERT INTO zips_new
     	      SELECT  RS.CEP AS CEP,
     		      RS.ENDERECO AS ENDERECO,
     		      RS.BAIRRO AS BAIRRO,
     		      RS.CIDADE AS CIDADE,
     		      RS.UF AS ESTADO,
     		      CASE RS.UF
     		      WHEN 'AC' THEN 'Acre'
     		      WHEN 'AL' THEN 'Alagoas'
     		      WHEN 'AP' THEN 'Amapá'
     		      WHEN 'AM' THEN 'Amazonas'
     		      WHEN 'BA' THEN 'Bahia'
     		      WHEN 'CE' THEN 'Ceará'
     		      WHEN 'DF' THEN 'Distrito Federal'
     		      WHEN 'ES' THEN 'Espírito Santo'
     		      WHEN 'GO' THEN 'Goiás'
     		      WHEN 'MA' THEN 'Maranhão'
     		      WHEN 'MT' THEN 'Mato Grosso'
     		      WHEN 'MS' THEN 'Mato Grosso do Sul'
     		      WHEN 'MG' THEN 'Minas Gerais'
     		      WHEN 'PA' THEN 'Pará'
     		      WHEN 'PB' THEN 'Paraíba'
     		      WHEN 'PR' THEN 'Paraná'
     		      WHEN 'PE' THEN 'Pernambuco'
     		      WHEN 'PI' THEN 'Piauí'
     		      WHEN 'RJ' THEN 'Rio de Janeiro'
     		      WHEN 'RN' THEN 'Rio Grande do Norte'
     		      WHEN 'RS' THEN 'Rio Grande do Sul'
     		      WHEN 'RO' THEN 'Rondônia'
     		      WHEN 'RR' THEN 'Rorâima'
     		      WHEN 'SC' THEN 'Santa Catarina'
     		      WHEN 'SP' THEN 'São Paulo'
     		      WHEN 'SE' THEN 'Sergipe'
     		      WHEN 'TO' THEN 'Tocantins'
							 END AS NOME_ESTADO,
							 CURRENT_TIMESTAMP inserted_at,
							 CURRENT_TIMESTAMP updated_at
     	      FROM (
     			SELECT  ifnull(log.CEP, loc.CEP) AS CEP,
     				CASE log.LOG_STA_TLO
     				WHEN 'S' THEN
     				  ifnull(log.TLO_TX, '') || ' ' || ifnull(log.LOG_NO, '')
     				ELSE
     				  ifnull(log.LOG_NO, '')
     				END ENDERECO,
     				ifnull(bai.BAI_NO, '')   AS BAIRRO,
     				loc.LOC_NO               AS CIDADE,
     				loc.UFE_SG               AS UF
     			FROM localidades loc
     			LEFT JOIN logradouros log ON log.LOC_NU = loc.LOC_NU
     			LEFT JOIN bairros bai     ON log.BAI_NU_INI = bai.BAI_NU

     			UNION ALL

     			SELECT  uni.CEP                  AS CEP,
     				uni.UOP_ENDERECO         AS ENDERECO,
     				ifnull(bai.BAI_NO, '')   AS BAIRRO,
     				loc.LOC_NO               AS CIDADE,
     				uni.UFE_SG               AS UF
     			FROM unidade_operacionals uni
     			LEFT JOIN bairros bai     ON uni.BAI_NU = bai.BAI_NU
     			LEFT JOIN localidades loc ON bai.LOC_NU = loc.LOC_NU

     			UNION ALL

     			SELECT  gra.CEP                  AS CEP,
     				gra.GRU_ENDERECO         AS ENDERECO,
     				ifnull(bai.BAI_NO, '')   AS BAIRRO,
     				loc.LOC_NO               AS CIDADE,
     				gra.UFE_SG               AS UF
     			FROM grande_usuarios gra
     			LEFT JOIN bairros bai     ON gra.BAI_NU = bai.BAI_NU
     			LEFT JOIN localidades loc ON bai.LOC_NU = loc.LOC_NU
     	      ) RS
     	      WHERE RS.CEP <> ''"
        DataMapper.repository(:default).adapter.execute('rename table zips TO zips_old')
        DataMapper.repository(:default).adapter.execute('rename table zips_new TO zips')
        DataMapper.repository(:default).adapter.execute('drop table zips_old')
      end
    end
  end

  private

  def self.get_adapter
    options = DataMapper.repository(:default).adapter.options
    options[:adapter] # Return
  end
end
