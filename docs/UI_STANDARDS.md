# KATANAOS UI Standards (v2.6+)

## 1. Global Dimensions
- **BOX_WIDTH:** `70` characters (Standard)
- **INDENT:** `2` spaces
- **Frame Style:** Double Line `╔ ═ ╗`, `║`, `╚ ═ ╝`
- **Colors:**
  - Border: `C_PURPLE` (Standard), `C_ORANGE` (Warning)
  - Text: `C_WHITE`, `C_NEON`, `C_GREEN`

## 2. Alignment Rules (CRITICAL)
To ensure a closed frame, precise padding calculation is required.

### Box Lines (`box_row`)
The padding formula must account for the border characters correctly.
- **Formula:** `pad = BOX_WIDTH - visible_len(content) - 1`
- **Why -1?**
  - `BOX_WIDTH` includes the left border/margin offset relative to the fill area.
  - `-1` adjustment ensures the right `║` lands exactly at column 70.
  - **DO NOT USE** `-2` (Result: Gap on right side).

### Status Lines (`print_status_line`)
- **Format:** `║ Label | Status ║`
- **Column 1 (Label):** `%-25s` (25 chars)
- **Column 2 (Status):** `%-40s` (40 chars)
- **Separators/Borders:** 5 chars (`║ ` ... ` | ` ... ` ║`)
- **Total:** 25 + 40 + 5 = 70.

## 3. ASCII Art
- **Centering:** Must be manually centered relative to the 70-char width.
- **Escape Safety:** Always use `cat << "EOF"` inside functions. **NEVER** remove the `cat` command (causes script execution of art).

## 4. Verification
After any UI change, run:
```bash
./katanaos.sh
```
Check:
1.  Is the right border `║` straight vertically?
2.  Is the top/bottom frame `╗/╝` connected to the side walls?
