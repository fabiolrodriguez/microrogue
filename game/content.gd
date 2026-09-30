class_name VigilContent
extends RefCounted

const PACK := "res://assets/Bitcrawl_Free_Roguelike_v1/"
const RELICS := ["edge", "haste", "echo", "mirror", "boots", "heart", "hunger", "fury"]
const ICONS := {"edge": 18, "haste": 5, "echo": 23, "mirror": 0, "boots": 10, "heart": 4, "hunger": 19, "fury": 17}
const TEXT := {
"tagline": ["UMA SALA. QUATRO SELOS. UMA ÚLTIMA VIGÍLIA.", "ONE ROOM. FOUR SEALS. ONE LAST VIGIL."],
"subtitle": ["Rompa os selos. Enfrente o Guardião. Veja a aurora.", "Break the seals. Face the Warden. See the dawn."],
"new_run": ["INICIAR VIGÍLIA", "BEGIN THE VIGIL"],
"title": ["A ÚLTIMA\nVIGÍLIA", "THE LAST\nVIGIL"],
"move": ["Mover", "Move"], "attack": ["Atacar (segure) · mira assistida", "Attack (hold) · aim assist"],
"roll": ["Esquivar · invulnerável durante o impulso", "Roll · invulnerable during the dash"],
"hint": ["WASD / setas  mover    J / Espaço  espada    K / Shift  esquiva    Esc  pausa", "WASD / arrows  move    J / Space  sword    K / Shift  roll    Esc  pause"],
"pad_hint": ["Analógico / direcional  mover    A  espada    B  esquiva    Start  pausa", "Stick / D-pad  move    A  sword    B  roll    Start  pause"],
"intro": ["SEGURE O ATAQUE • a espada mira no inimigo próximo", "HOLD ATTACK • your sword aims at nearby enemies"],
"seal": ["SELO %d / 4", "SEAL %d / 4"], "boss": ["O GUARDIÃO", "THE WARDEN"],
"stage_1": ["I · O despertar", "I · The awakening"], "stage_2": ["II · Ossos inquietos", "II · Restless bones"],
"stage_3": ["III · A cripta respira", "III · The crypt breathes"], "stage_4": ["IV · Antes da aurora", "IV · Before the dawn"],
"survive": ["Resista à invocação", "Survive the summoning"], "cleanup": ["Elimine os inimigos restantes", "Clear the remaining enemies"],
"chest": ["Selo rompido! Vá ao baú no centro", "Seal broken! Reach the central chest"],
"choose": ["ESCOLHA SUA RELÍQUIA", "CHOOSE YOUR RELIC"],
"choice_hint": ["Uma escolha por selo • +1 vida ao abrir o baú", "One choice per seal • +1 health on opening the chest"],
"continue": ["CONTINUAR", "CONTINUE"], "retry": ["TENTAR NOVAMENTE", "TRY AGAIN"], "menu": ["MENU PRINCIPAL", "MAIN MENU"],
"victory": ["A AURORA É SUA", "THE DAWN IS YOURS"], "defeat": ["A VIGÍLIA TERMINOU", "THE VIGIL HAS ENDED"],
"win_text": ["Os quatro selos se apagam. A cripta finalmente descansa.", "The four seals fade. The crypt is finally at rest."],
"lose_text": ["A cripta lembra. Erga a espada mais uma vez.", "The crypt remembers. Raise your sword once more."],
"stats": ["%d inimigos derrotados   •   %s   •   Relíquias: %d", "%d enemies defeated   •   %s   •   Relics: %d"],
"ready": ["ESQUIVA PRONTA", "ROLL READY"], "cooldown": ["ESQUIVA %.1fs", "ROLL %.1fs"],
"warning": ["As pedras despertam. Evite os pisos marcados!", "The stones awaken. Avoid marked tiles!"],
"boss_intro": ["O ÚLTIMO SELO SE ABRE", "THE FINAL SEAL OPENS"],
"enrage": ["O Guardião se enfurece!", "The Warden is enraged!"],
"edge_name": ["Lâmina longa", "Long blade"], "edge_desc": ["+50% de alcance e +1 de dano. Acerte grupos inteiros.", "+50% reach and +1 damage. Cut through entire groups."],
"haste_name": ["Anel do ímpeto", "Ring of haste"], "haste_desc": ["Ataque 40% mais rápido. Pressione sem dar trégua.", "Attack 40% faster. Keep the pressure on."],
"echo_name": ["Espada do eco", "Echo blade"], "echo_desc": ["Cada golpe lança uma onda que atravessa inimigos.", "Every swing launches a wave that pierces enemies."],
"mirror_name": ["Escudo espelhado", "Mirror shield"], "mirror_desc": ["A espada reflete projéteis próximos contra os inimigos.", "Your sword reflects nearby projectiles back at enemies."],
"boots_name": ["Passo espectral", "Ghost step"], "boots_desc": ["Esquiva recarrega em metade do tempo. +15% de velocidade.", "Roll recharges twice as fast. +15% movement speed."],
"heart_name": ["Coração de âmbar", "Amber heart"], "heart_desc": ["+2 de vida máxima e cura completa agora.", "+2 maximum health and fully heal now."],
"hunger_name": ["Frasco da colheita", "Harvest flask"], "hunger_desc": ["Recupere 1 de vida a cada 8 inimigos derrotados.", "Recover 1 health for every 8 enemies defeated."],
"fury_name": ["Voto da fúria", "Vow of fury"], "fury_desc": ["+2 de dano. Com metade da vida ou menos, +4 em vez de +2.", "+2 damage. At half health or less, gain +4 instead."],
"about": ["5–10 MIN  /  PIXEL ART: BITCRAWL", "5–10 MIN  /  PIXEL ART: BITCRAWL"]
}

static func install() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var loc = tree.root.get_node("LocalizationManager")
	for key in TEXT:
		loc.translations.pt_BR["v_" + key] = TEXT[key][0]
		loc.translations.en_US["v_" + key] = TEXT[key][1]
	loc.translations.pt_BR.menu_start = TEXT.new_run[0]
	loc.translations.en_US.menu_start = TEXT.new_run[1]
	tree.root.get_node("ControlsManager").set_controls_data([
		{"label_key":"v_move", "value":"WASD / ↑ ↓ ← → / L-stick / D-pad"},
		{"label_key":"v_attack", "action":"attack"},
		{"label_key":"v_roll", "action":"roll"},
		{"label_key":"controls_pause", "action":"pause"},
		{"label_key":"controls_confirm", "action":"ui_accept"},
		{"label_key":"controls_cancel", "action":"ui_cancel"}])

static func text(key: String) -> String:
	return (Engine.get_main_loop() as SceneTree).root.get_node("LocalizationManager").tr_key("v_" + key)

static func icon(id: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = load(PACK + "Items/Items_Normal_Outline.png")
	texture.region = Rect2((id % 5) * 16, (id / 5) * 16, 16, 16)
	return texture
