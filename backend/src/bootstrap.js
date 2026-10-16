const bcrypt = require('bcryptjs');
const { query } = require('./db');

const DEMO = [
  { usuario: 'admin', clave: 'admin123', id_rol: 1, nombres: 'Carlos', apellidos: 'Mena', socio: null },
  { usuario: 'biblio', clave: 'biblio123', id_rol: 2, nombres: 'Lucía', apellidos: 'Paredes', socio: null },
  { usuario: 'lector', clave: 'lector123', id_rol: 3, nombres: 'Bryan', apellidos: 'Quishpe Lema', socio: 'S-0001' },
];

async function asegurarCuentas() {
  await query(`
    ALTER TABLE sert_usuario
      ADD COLUMN IF NOT EXISTS id_socio INT REFERENCES sert_socio (id_socio)
  `);
  await query(`
    CREATE OR REPLACE VIEW sert_v_prestamos_vencidos AS
    SELECT p.id_prestamo, s.nombres || ' ' || s.apellidos AS socio, l.titulo,
           (CURRENT_DATE - p.fecha_vencimiento) AS dias_retraso
      FROM sert_prestamo p
      JOIN sert_socio s ON s.id_socio = p.id_socio
      JOIN sert_detalle_prestamo d ON d.id_prestamo = p.id_prestamo
      JOIN sert_ejemplar e ON e.id_ejemplar = d.id_ejemplar
      JOIN sert_libro l ON l.id_libro = e.id_libro
     WHERE p.estado = 'ABIERTO' AND d.fecha_devolucion IS NULL
       AND p.fecha_vencimiento < CURRENT_DATE
  `);

  for (const cuenta of DEMO) {
    const hash = await bcrypt.hash(cuenta.clave, 10);
    let idSocio = null;
    if (cuenta.socio) {
      const socio = await query('SELECT id_socio FROM sert_socio WHERE codigo = $1', [cuenta.socio]);
      idSocio = socio.rows[0]?.id_socio || null;
    }
    await query(
      `INSERT INTO sert_usuario (id_rol, nombres, apellidos, usuario, clave_hash, id_socio)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (usuario) DO UPDATE
         SET clave_hash = EXCLUDED.clave_hash,
             id_rol = EXCLUDED.id_rol,
             nombres = EXCLUDED.nombres,
             apellidos = EXCLUDED.apellidos,
             activo = TRUE,
             id_socio = EXCLUDED.id_socio`,
      [cuenta.id_rol, cuenta.nombres, cuenta.apellidos, cuenta.usuario, hash, idSocio]
    );
  }
}

async function preparar() {
  if (String(process.env.DEMO_ACCOUNTS || 'true') === 'false') return;
  try {
    await asegurarCuentas();
    console.log('Cuentas de prueba listas: admin, biblio y lector');
  } catch (err) {
    console.error('No se pudieron preparar las cuentas de prueba:', err.message);
    console.error('Ejecute database/sert_biblioteca.sql sobre PostgreSQL y vuelva a iniciar la API.');
  }
}

module.exports = { preparar };
