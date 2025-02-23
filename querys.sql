-- Consultas
-- CONSULTA D
/*
 Esta consulta obtiene un reporte completo de empleados que cumplen con al menos una de estas características:
 - Han vendido productos en más de 1 sucursal.
 - Trabajan en la misma sucursal que su supervisor.
 - Tienen un cargo que se encuentra entre los 5 mejores pagados de la empresa.
 
 El reporte incluye:
 - Información de empleado (CI, nombre completo, sexo).
 - Información del cargo (nombre).
 - Información de su sueldo detallada (salario base por su cargo por hora, bono fijo mensual, total por mes que obtiene el empleado dadas sus horas y días trabajados y monto total recibido desde 
 el inicio de su contrato).
 */
SELECT
  DISTINCT e.CI,
  e.nombre || ' ' || e.apellido AS nombreCompleto,
  e.sexo,
  c.nombre AS nombreCargo,
  c.salarioBasePorHora AS salarioBasePorHora,
  COALESCE(e.bonoFijoMensual, 0) AS bonoFijoMensual,
  (c.salarioBasePorHora * e.cantidadDiasTrabajoPorSemana * 4 * (e.horaFin - e.horaInicio)) + (COALESCE(e.bonoFijoMensual, 0)) AS totalMensual, 
  --Se suma el SalarioHora * Dias trabajados * 4 para tener el mes * cantidad de Horas todo eso + el bono fijo mensual nos daria el monto total ganado durante el mes
  (c.salarioBasePorHora * e.cantidadDiasTrabajoPorSemana * (e.horaFin - e.horaInicio) * (CAST((JULIANDAY(DATE('now')) - JULIANDAY(DATE(e.fechaContrato)))/7 AS INTEGER))) +
  (COALESCE(e.bonoFijoMensual, 0) * ((EXTRACT(year FROM AGE(NOW(), e.fechaContrato)) * 12) + (EXTRACT(month FROM AGE(NOW(), e.fechaContrato))))) AS montoTotalRecibido
  /*
  (CAST((JULIANDAY(DATE('now')) - JULIANDAY(DATE(e.fechaContrato)))/7 AS INTEGER)): Esto es la cantidad de semanas que llevo trabajando desde que se inicio el contrato. se multiplica por la cantidad de dias
  trabajados por semana y este resultado por la cantidad de horas trabajadas por dia, asi obtenemos el total de su sueldo base ganado por horas trabajadas desde que empezo el contrato.
  (COALESCE(e.bonoFijoMensual, 0) * ((EXTRACT(year FROM AGE(NOW(), e.fechaContrato)) * 12) + (EXTRACT(month FROM AGE(NOW(), e.fechaContrato))))): Con esto obtenemos la cantidad total de bonos mensuales
  obtenidos desde que empezo el contrato.
  */
  FROM Empleado e
  JOIN Cargo c ON e.cargoId = c.id
  LEFT JOIN
    (SELECT empleadoId, COUNT(DISTINCT sucursalId) AS sucursalesDistintas
     FROM VentaFisica
     GROUP BY empleadoId) sv ON e.id = sv.empleadoId
     -- Obtenemos la lista de empleados y una columna con un count del total de sucursales en las que han tenido ventas
  WHERE
    COALESCE(sv.sucursalesDistintas, 0) > 1
    -- Verificamos si el total de sucursales donde haya vendido sea mayor que 1, con el COALESCE verificamos que los valores no sean nulos, osea empleados que no hayan tenido ventas todavia.
    OR e.id IN (SELECT e1.id
                FROM Empleado e1
                JOIN Empleado e2 ON e1.empleadoSupervisorId = e2.id
                WHERE e1.sucursalId = e2.sucursalId)
    -- Verificamos si el empleado esta en una lista de empleados cuyos supervisores trabajan en la misma sucursal que el.
    OR e.cargoId IN (SELECT id
                     FROM Cargo
                     ORDER BY salarioBasePorHora DESC
                     LIMIT 5);
    -- Obtenemos una lista de los 5 mejores salarios por cargo y verificamos que el Id Cargo de nuestro empleado este dentro de dicha lista.