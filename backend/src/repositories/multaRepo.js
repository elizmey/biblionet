const { query } = require('../db');

async function pendientesDeSocio(idSocio) {
  const { rows } = await query(
    `SELECT count(*)::int AS n
       FROM sert_multa m
       JOIN sert_detalle_prestamo d ON d.id_detalle = m.id_detalle
       JOIN sert_prestamo p ON p.id_prestamo = d.id_prestamo
      WHERE p.id_socio = $1 AND m.estado = 'PENDIENTE'`,
    [idSocio]
  );
  return rows[0].n;
}

async function listar() {
  const { rows } = await query(
    `SELECT m.id_multa, m.id_detalle, m.dias_retraso, m.monto, m.estado, m.fecha_pago,
            s.nombres || ' ' || s.apellidos AS socio, l.titulo, e.codigo_barras
       FROM sert_multa m
       JOIN sert_detalle_prestamo d ON d.id_detalle = m.id_detalle
       JOIN sert_prestamo p ON p.id_prestamo = d.id_prestamo
       JOIN sert_socio s ON s.id_socio = p.id_socio
       JOIN sert_ejemplar e ON e.id_ejemplar = d.id_ejemplar
       JOIN sert_libro l ON l.id_libro = e.id_libro
      ORDER BY m.estado, m.id_multa DESC`
  );
  return rows;
}

async function listarDeSocio(idSocio) {
  const { rows } = await query(
    `SELECT m.id_multa, m.id_detalle, m.dias_retraso, m.monto, m.estado, m.fecha_pago,
            s.nombres || ' ' || s.apellidos AS socio, l.titulo, e.codigo_barras
       FROM sert_multa m
       JOIN sert_detalle_prestamo d ON d.id_detalle = m.id_detalle
       JOIN sert_prestamo p ON p.id_prestamo = d.id_prestamo
       JOIN sert_socio s ON s.id_socio = p.id_socio
       JOIN sert_ejemplar e ON e.id_ejemplar = d.id_ejemplar
       JOIN sert_libro l ON l.id_libro = e.id_libro
      WHERE p.id_socio = $1
      ORDER BY m.estado, m.id_multa DESC`,
    [idSocio]
  );
  return rows;
}

async function pagar(id) {
  const { rowCount } = await query(
    `UPDATE sert_multa
        SET estado = 'PAGADA', fecha_pago = now()
      WHERE id_multa = $1 AND estado = 'PENDIENTE'`,
    [id]
  );
  return rowCount;
}

module.exports = { pendientesDeSocio, listar, listarDeSocio, pagar };
