extends RichTextLabel
var slapoha = false

func _physics_process(delta: float) -> void:
	
	if slapoha == false:
		if Global.chat_on == true:
			$"../../Timer".start()
			slapoha = true
			print("FOI")

func chat():
	$".".text += (Users.pick_random()) + ": "+ mensagens.pick_random() + "\n"
	


var mensagens = [
	"Oieee!", "A Live já Começou?", "Caramba!!!", "To curtindo a live!", "Pog! :O",
	"Gente a live já começou?", "Jogo Novo?", "Quando Você vai jogar Crossout???",
	"chegueiii", "salveee família", "primeirooo!", "boa noite tropaaa",
	"vamo que vamo 🔥", "já cheguei dando like", "opa opa opa", "cheguei cedo hj",
	"fui notificado agora", "boraaaaa", "finalmenteee kkk", "salve streamer brabo",
	"partiu gameplay", "a tropa chegou 😎", "quero ver jogando no hard", "abriu a live cedo hoje?",
	"me nota pls", "tô desde o começo!", "qual jogo vai ser hoje?", "bora bater recorde",
	"cheguei atrasado?", "eitaaa já começou", "qual jogo hj?", "vamo pra cima",
	"essa live promete", "cheguei pra dar sorte", "já peguei minha pipoca 🍿", "streamer mais brabo do BR",
	"bora clipar tudo", "live raiz demais", "já tava com saudade", "fala comigo chat",
	"essa skin é linda", "tá rodando liso aí?", "vai zerar hoje?", "chat tá on fire",
	"tropa representando", "manda salve pra mim", "hoje vai ser histórico", "só vitória"
]
var Users = [
	"XxDragonSlayerxX", "NoobMaster22", "LuluGamer", "TropaDoZap",
	"SniperBR", "Darkzinho", "ClutchGod", "AnaPlay",
	"SpeedRunMano", "Pixelada", "R4t0L0k0", "BiaFPS",
	"ShadowBR", "ReiDoClutch", "TeteuGame", "N1njaDoRole",
	"GatinhoPro", "ZeroPing", "FuriaDoTeclado", "JuJuCraft",
	"BatataQuente", "SniperDeChinelo", "MestreDoLag", "ClaudinhoPRO",
	"SlaMano", "FoguetinhoBR", "RachaTela", "M1nerva",
	"DogaoSemFreio", "ZoeiraTotal", "PixelDoMal", "KibeAssassino",
	"ManoDoX1", "ToSemSono", "LendarioBR", "CaféComLeite",
	"RatoDeLan", "TioDoPavê", "NoiaDoGame", "ProPlayerDeMesa"
]


func _on_timer_timeout() -> void:
	chat()
