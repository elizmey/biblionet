const { query } = require('../db');

async function resumen() {
  const { rows } = await query(`
    SELECT
      (SELECT count(*)::int FROM sert_libro) AS titulos,
      (SELECT count(*)::int FROM sert_ejemplar WHERE estado = 'DISPONIBLE') AS disponibles,
      (SELECT count(*)::int FROM sert_ejemplar WHERE estado <> 'BAJA') AS ejemplares,
      (SELECT count(*)::int FROM sert_socio WHERE estado = 'ACTIVO') AS socios_activos,
      (SELECT count(*)::int FROM sert_prestamo WHERE estado = 'ABIERTO') AS prestamos_abiertos,
      (SELECT count(DISTINCT id_prestamo)::int FROM sert_v_prestamos_vencidos) AS prestamos_vencidos,
      (SELECT COALESCE(sum(monto), 0) FROM sert_multa WHERE estado = 'PENDIENTE') AS multas_pendientes
  `);
  const vencidos = await query(`
    SELECT DISTINCT id_prestamo, socio, titulo, dias_retraso
      FROM sert_v_prestamos_vencidos
     ORDER BY dias_retraso DESC
  `);
  const stock = await query(`
    SELECT id_libro, titulo, isbn, total, disponibles
      FROM sert_v_disponibilidad
     WHERE disponibles <= 1
     ORDER BY disponibles, titulo
  `);
  return {
    indicadores: rows[0],
    vencidos: vencidos.rows,
    stockBajo: stock.rows,
  };
}

async function masPrestados() {
  const { rows } = await query(`
    SELECT l.titulo, count(d.id_detalle)::int AS veces
      FROM sert_detalle_prestamo d
      JOIN sert_ejemplar e ON e.id_ejemplar = d.id_ejemplar
      JOIN sert_libro l ON l.id_libro = e.id_libro
     GROUP BY l.id_libro, l.titulo
     ORDER BY veces DESC, l.titulo
  `);
  return rows;
}

module.exports = { resumen, masPrestados };
