WITH
    ConteoPaises AS (
        SELECT IdMoneda, COUNT(*) AS CantidadPaises
        FROM pais
        GROUP BY IdMoneda
    ),
    
    FechaValorUltimoCambio AS (
        SELECT
            IdMoneda,
            Fecha AS FechaUltimoCambio,
            Cambio AS ValorUltimoCambio,
            ROW_NUMBER() OVER(PARTITION BY IdMoneda ORDER BY Fecha DESC) as rn
        FROM cambiomoneda
    ),
    
    Promedio30Dias AS (
        SELECT IdMoneda, AVG(Cambio) AS PromedioCambio30Dias
        FROM cambiomoneda
        WHERE Fecha >= DATEADD(day, -30, GETDATE())
        GROUP BY IdMoneda
    ),
    
    -- Utlizando Desviación Estándar
    VolatilidadMoneda AS (
        SELECT IdMoneda, STDEV(Cambio) AS ValorVolatilidad
        FROM cambiomoneda
        GROUP BY IdMoneda
    )

SELECT
	m.Id,
    m.Moneda,
    m.Sigla,
    COALESCE(cp.CantidadPaises, 0) AS TotalPaises,
    rc.FechaUltimoCambio AS UltimaFecha,
    rc.ValorUltimoCambio AS UltimoCambio,
    p30.PromedioCambio30Dias AS Promedio30Dias,
    
    CASE
        WHEN vm.ValorVolatilidad IS NULL THEN 'Sin Datos'
        WHEN vm.ValorVolatilidad > 0.50 THEN 'Alta'
        WHEN vm.ValorVolatilidad > 0.10 THEN 'Media'
        ELSE 'Estable'
    END AS ClasificacionVolatilidad,
	DENSE_RANK() OVER(ORDER BY COALESCE(cp.CantidadPaises, 0) DESC) AS RankingUso
    
FROM
    moneda m
LEFT JOIN
    ConteoPaises cp ON m.Id = cp.IdMoneda
LEFT JOIN
    VolatilidadMoneda vm ON m.Id = vm.IdMoneda
LEFT JOIN
    Promedio30Dias p30 ON m.Id = p30.IdMoneda
LEFT JOIN
    FechaValorUltimoCambio rc ON m.Id = rc.IdMoneda AND rc.rn = 1
ORDER BY
    RankingUso ASC,
    m.Moneda ASC;