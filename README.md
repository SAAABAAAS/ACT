<div align="center">

# 🌍 ACT — Inclusive Solutions

**Seguridad y Salud en el Trabajo (SST), bienestar laboral e inclusión de personas con discapacidad para empresas en Ecuador.**

`Estado: pre-MVP / validación` · `Mercado inicial: Ecuador` · `Equipo: 5 cofundadores`

</div>

---

## 📌 Qué es esto

Este repositorio contiene **el producto tecnológico de ACT**: la base de datos y el agente de IA **"Inclusive Solutions SSO Intelligence"**, que ayuda a las empresas a saber qué obligaciones de SST cumplen, cuáles no y qué hacer, **siempre con revisión humana y citando normativa verificada**.

La visión completa de la empresa (pilares, productos educativos, valores) está en [`docs/vision.md`](docs/vision.md).

## 🎯 Foco actual (próximos 2–3 meses)

Ser una empresa que **cobra**. Por eso el producto arranca con **una sola cosa**:

> **Diagnóstico de cumplimiento SST** para pequeñas empresas: revisamos qué exige la norma según su tamaño, marcamos qué cumple, qué no, y entregamos un plan de acción.

Todo lo demás (muñecos educativos, experiencia interactiva, seguros) espera hasta validar esto. Detalle en [`docs/producto-mvp.md`](docs/producto-mvp.md).

## 🗂️ Estructura del repositorio

```
ACT/
├── README.md                    ← estás aquí
├── docs/
│   ├── vision.md                ← visión, pilares y valores de ACT
│   ├── producto-mvp.md          ← problema, hipótesis, alcance del MVP y métricas
│   ├── modelo-datos.md          ← explicación de la base de datos (con diagrama)
│   ├── guia-github.md           ← cómo trabajamos con GitHub (léanla todos)
│   ├── normativa/README.md      ← cómo se agrega y verifica normativa
│   └── estrategia/              ← Mapa de Gaps y documentos de la aceleradora
├── supabase/
│   ├── migrations/              ← esquema de la base de datos, en orden
│   ├── seed.sql                 ← datos de PRUEBA (todo ficticio)
│   └── pruebas_locales/         ← pruebas de seguridad del esquema
├── agent/
│   └── prompts/                 ← instrucciones del agente SSO Intelligence (versionadas)
├── .env.example                 ← variables de entorno, sin secretos
└── .gitignore
```

## 🧱 Tecnología

| Pieza | Herramienta | Por qué |
|---|---|---|
| Base de datos + login + archivos | [Supabase](https://supabase.com) (PostgreSQL) | Plan gratuito, login y almacenamiento incluidos, seguridad por filas (RLS) |
| Agente de IA | API de un modelo de lenguaje (ej. Claude) | Responde solo con normativa de la base, nunca de memoria |
| Interfaz (siguiente paso) | Por decidir | Primero validar con clientes usando el diagnóstico "a mano" |

## 🚀 Cómo levantar la base de datos

**Opción A — En la nube (la más fácil):**
1. Crear un proyecto gratis en [supabase.com](https://supabase.com).
2. Ir a **SQL Editor** y ejecutar, en este orden, los archivos de `supabase/migrations/`.
3. (Opcional) Ejecutar `supabase/seed.sql` para cargar la empresa ficticia de demostración.
4. Registrarse en la app y nombrar al primer administrador desde el SQL Editor:
   ```sql
   update public.perfiles set es_equipo_act = true where email = 'tu-correo@ejemplo.com';
   ```

**Opción B — Local (para quien programa):**
```bash
npm install -g supabase       # o: brew install supabase/tap/supabase
supabase start                # necesita Docker
supabase db reset             # aplica migraciones + seed.sql
```

Copiar `.env.example` a `.env` y completar las llaves. **El archivo `.env` nunca se sube a GitHub.**

## 🔐 Reglas que no se negocian

1. **Nada de datos reales de clientes en el repositorio.** Ni nombres, ni cédulas, ni RUC, ni documentos. Este repo es **público**.
2. **El agente no inventa normativa.** Solo cita fuentes que una persona verificó contra el texto oficial.
3. **Ninguna respuesta de IA llega a un cliente sin revisión humana.** La base de datos lo impide.
4. **Datos de salud y discapacidad**: van en tablas aparte, con acceso restringido y consentimiento del trabajador (Ley Orgánica de Protección de Datos Personales). Aún no están en el esquema.
5. **Nada se sube directo a `main`**: todo cambio entra por Pull Request (ver [`docs/guia-github.md`](docs/guia-github.md)).

## 👥 Equipo

| Persona | Rol | Dueño de… |
|---|---|---|
| Felipe Tapia | CEO & Product Manager | `docs/producto-mvp.md`, prioridades |
| Sebastián Cervantes | CTO / Tecnología e IA | `supabase/`, `agent/` |
| Margeory Rodriguez | Operaciones y servicios | Proceso del diagnóstico, `docs/normativa/` |
| Camila Varea | Desarrollo comercial y experiencia del cliente | Entrevistas y pilotos |
| Dayana Baldeon | Marketing & Brand | Marca, `docs/vision.md` |

## 🗺️ Hoja de ruta

- [x] Esquema núcleo de base de datos con seguridad por filas
- [ ] Verificar las primeras 10–15 obligaciones con un profesional SST
- [ ] Realizar 5–10 entrevistas a empresas y 1 diagnóstico piloto
- [ ] Definir precio del diagnóstico
- [ ] Primera versión del agente con revisión humana
- [ ] Interfaz mínima para el cliente

---

<div align="center">

**Cumplimiento. Bienestar. Inclusión.**

</div>
