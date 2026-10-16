const { pool, query } = require('../db');

const DETALLE_SQL = `
  SELECT p.id_prestamo, p.id_socio, p.id_usuario, p.fecha_prestamo, p.fecha_vencimiento, p.estado,
         s.nombres || ' ' || s.apellidos AS socio,
         s.codigo AS codigo_socio,
         u.usuario AS atendido_por,
         d.id_detalle, d.id_ejemplar, d.fecha_devolucion,
         e.codigo_barras, l.titulo,
         CASE
           WHEN d.fecha_devolucion IS NULL AND p.fecha_vencimiento < CURRENT_DATE
           THEN (CURRENT_DATE - p.fecha_vencimiento)
           ELSE 0
         END AS dias_retraso
    FROM sert_prestamo p
    JOIN sert_socio s ON s.id_socio = p.id_socio
    JOIN sert_usuario u ON u.id_usuario = p.id_usuario
    JOIN sert_detalle_prestamo d ON d.id_prestamo = p.id_prestamo
    JOIN sert_ejemplar e ON e.id_ejemplar = d.id_ejemplar
    JOIN sert_libro l ON l.id_libro = e.id_libro
`;

function agrupar(rows) {
  const map = new Map();
  for (const row of rows) {
    if (!map.has(row.id_prestamo)) {
      map.set(row.id_prestamo, {
        id_prestamo: row.id_prestamo,
        id_socio: row.id_socio,
        socio: row.socio,
        codigo_socio: row.codigo_socio,
        atendido_por: row.atendido_por,
        fecha_prestamo: row.fecha_prestamo,
        fecha_vencimiento: row.fecha_vencimiento,
        estado: row.estado,
        detalles: [],
      });
    }
    map.get(row.id_prestamo).detalles.push({
      id_detalle: row.id_detalle,
      id_ejemplar: row.id_ejemplar,
      codigo_barras: row.codigo_barras,
      titulo: row.titulo,
      fecha_devolucion: row.fecha_devolucion,
      dias_retraso: Number(row.dias_retraso),
    });
  }
  return [...map.values()];
}

async function listar({ idSocio } = {}) {
  const params = [];
  let sql = DETALLE_SQL;
  if (idSocio) {
    params.push(idSocio);
    sql += ` WHERE p.id_socio = $1`;
  }
  sql += ' ORDER BY p.fecha_prestamo DESC, d.id_detalle';
  const { rows } = await query(sql, params);
  return agrupar(rows);
}

async function vencidosDeSocio(idSocio) {
  const { rows } = await query(
    `SELECT count(*)::int AS n
       FROM sert_prestamo
      WHERE id_socio = $1 AND estado = 'ABIERTO' AND fecha_vencimiento < CURRENT_DATE`,
    [idSocio]
  );
  return rows[0].n;
}

async function detalle(idDetalle) {
  const { rows } = await query(
    'SELECT id_detalle, id_prestamo, fecha_devolucion FROM sert_detalle_prestamo WHERE id_detalle = $1',
    [idDetalle]
  );
  return rows[0] || null;
}

async function registrar({ idSocio, idUsuario, ejemplares }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows: [p] } = await client.query(
      `INSERT INTO sert_prestamo (id_socio, id_usuario, fecha_vencimiento)
       VALUES ($1, $2, CURRENT_DATE + (SELECT valor::int FROM sert_parametro WHERE clave = 'DIAS_PRESTAMO'))
       RETURNING id_prestamo`,
      [idSocio, idUsuario]
    );
    for (const idEjemplar of ejemplares) {
      await client.query(
        'INSERT INTO sert_detalle_prestamo (id_prestamo, id_ejemplar) VALUES ($1, $2)',
        [p.id_prestamo, idEjemplar]
      );
    }
    await client.query('COMMIT');
    return p.id_prestamo;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function devolver(idDetalle) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      'SELECT sert_fn_devolver($1) AS monto',
      [idDetalle]
    );
    await client.query('COMMIT');
    return rows[0].monto;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

module.exports = { listar, vencidosDeSocio, detalle, registrar, devolver };
