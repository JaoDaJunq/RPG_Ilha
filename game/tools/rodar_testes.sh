#!/usr/bin/env bash
# Roda TODAS as game/tests/*_smoke.tscn sem janela e reprova a cena se ela
#   - passar de 120 s,
#   - imprimir "SCRIPT ERROR",
#   - tiver linha começando com "[FALHA]",
#   - ou não imprimir "RESULTADO: OK".
# Uso (da raiz do repositório):  bash game/tools/rodar_testes.sh
# GODOT=<binário> escolhe o Godot (padrão: o 4.7.2 instalado no Windows).
G="${GODOT:-$LOCALAPPDATA/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")/../.." || exit 1
# Reimporta antes, para registrar classes (class_name) e assets novos.
"$G" --headless --path game --import >/dev/null 2>&1
status=0
for t in game/tests/*_smoke.tscn; do
	n=$(basename "$t" .tscn)
	inicio=$(date +%s)
	code=0
	out=$(timeout 120 "$G" --headless --path game "res://tests/$n.tscn" 2>&1) || code=$?
	printf '%s\n' "$out" | grep -aE '^\[(OK|FALHA)\]|RESULTADO|SCRIPT ERROR|^ERROR' || true
	dur=$(( $(date +%s) - inicio ))
	motivo=""
	if [ $code -eq 124 ]; then
		motivo="passou de 120 s"
	elif printf '%s\n' "$out" | grep -aq 'SCRIPT ERROR'; then
		motivo="SCRIPT ERROR"
	elif printf '%s\n' "$out" | grep -aq '^\[FALHA\]'; then
		motivo="linha [FALHA]"
	elif ! printf '%s\n' "$out" | grep -aq 'RESULTADO: OK'; then
		motivo="sem 'RESULTADO: OK'"
	fi
	if [ -z "$motivo" ]; then
		echo "OK    $n (${dur} s)"
	else
		echo "FALHA $n (${dur} s): $motivo"
		status=1
	fi
done
echo "BATERIA: $([ $status = 0 ] && echo 'tudo OK' || echo 'com falhas')"
exit $status
