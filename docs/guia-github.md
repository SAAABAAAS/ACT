# Cómo trabajamos con GitHub en ACT

Guía para todo el equipo, programen o no. Con 3–6 horas por semana cada uno, el orden ahorra más tiempo del que cuesta.

## 1. Conceptos en 1 minuto

| Palabra | Qué es |
|---|---|
| **Repositorio (repo)** | La carpeta del proyecto en la nube, con todo su historial. |
| **`main`** | La versión oficial. Lo que está aquí es lo que vale. |
| **Rama (branch)** | Una copia para trabajar sin tocar `main`. |
| **Commit** | Un "guardar" con una descripción de qué cambió. |
| **Pull Request (PR)** | Pedir que los cambios de una rama entren a `main`. Otra persona revisa y aprueba. |
| **Issue** | Una tarea, idea o problema anotado en GitHub. |

## 2. Reglas del equipo

1. **Nadie sube directo a `main`.** Todo entra por Pull Request.
2. **Cada PR lo aprueba al menos otra persona.** Código y base de datos: Sebastián. Normativa: Margeory + el profesional SST. Producto: Felipe.
3. **El repo es público.** Nunca suban contraseñas, llaves de API, el archivo `.env`, ni datos o documentos de clientes reales.
4. **Un PR = un tema.** "Agrego tabla de incidentes" sí; "agrego incidentes, cambio el README y arreglo el logo" no.
5. **Las tareas viven en Issues**, no en el chat de WhatsApp. Si se decidió algo en una reunión, se anota en el Issue.

## 3. Si NO programas (desde la web de GitHub)

Para editar un documento (por ejemplo `docs/producto-mvp.md`):

1. Abre el archivo en github.com y presiona el ícono del lápiz ✏️.
2. Haz tu cambio.
3. Presiona **Commit changes…** → elige **"Create a new branch for this commit and start a pull request"** → ponle un nombre como `docs/precios-piloto`.
4. Escribe qué cambiaste y por qué → **Propose changes** → **Create pull request**.
5. Avisa en el grupo a quien debe revisarlo.

Para subir un archivo (PDF, imagen): en la carpeta correspondiente, **Add file → Upload files**, y luego el mismo paso 3.

## 4. Si programas (desde la terminal)

```bash
git clone https://github.com/SAAABAAAS/ACT.git
cd ACT

git checkout main && git pull           # partir siempre de lo último
git checkout -b feat/tabla-incidentes   # rama nueva para tu tarea

# ... trabajas ...
git add supabase/migrations/20261201120000_incidentes.sql
git commit -m "feat(db): agrega tabla de incidentes con RLS"
git push -u origin feat/tabla-incidentes
# luego abre el Pull Request en GitHub
```

### Nombres de ramas
| Prefijo | Para |
|---|---|
| `feat/` | algo nuevo (tabla, función, pantalla) |
| `fix/` | arreglar un error |
| `docs/` | documentación |
| `norma/` | agregar o verificar normativa |

### Mensajes de commit
Corto, en español, en presente: `tipo(área): qué hace`
- `feat(db): agrega vista de cumplimiento por sede`
- `fix(rls): el rol lectura ya no puede crear acciones`
- `docs(mvp): actualiza hipótesis tras 3 entrevistas`

## 5. Configuración recomendada del repo (la hace el dueño del repo, una vez)

- **Settings → Branches → Add branch protection rule** para `main`: marcar *Require a pull request before merging* y *Require approvals (1)*.
- **Settings → Collaborators**: invitar a los 5 integrantes.
- **Issues**: crear etiquetas `producto`, `base-de-datos`, `agente-ia`, `normativa`, `comercial`.
- Evaluar si el repo debe pasar a **privado** cuando haya lógica de negocio o datos de clientes en juego. Hoy es público.

## 6. ¿Qué NO va en este repo?

| No va aquí | Dónde va |
|---|---|
| Entrevistas con nombres de personas reales | Drive del equipo (carpeta privada) |
| Documentos de clientes | Supabase Storage (bucket privado `documentos`) |
| Llaves de API y contraseñas | `.env` local + variables de entorno del servidor |
| Contratos, facturas | Drive del equipo |
