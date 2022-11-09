#pragma semicolon 1
#pragma newdecls required

Handle
	hTimerFlood[MAXPLAYERS+1];

bool
	bLogsSay[MAXPLAYERS+1],
	bEnable;

int
	iCountUse[MAXPLAYERS+1],
	iCountCmd;
	
float
	fFloodCheck,
	fFloodCount[MAXPLAYERS+1];

char
	sFile[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "Limit CMD",
	author = "Nek.'a 2x2 | ggwp.site ",
	description = "Anti-Flood/Анти спам командами",
	version = "1.0",
	url = "https://ggwp.site/"
};

public void OnPluginStart()
{
	ConVar cvar;
	cvar = CreateConVar("sm_cmd_flood_enable", "1", "Включить/Выключить плагин", _, true, 0.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Enable);
	bEnable = cvar.BoolValue;
	
	cvar = CreateConVar("sm_cmd_flood_time", "1.5", "В какой период времени делать проверку");
	cvar.AddChangeHook(CVarChangedf_Flood);
	fFloodCheck = cvar.FloatValue;
	
	cvar = CreateConVar("sm_cmd_flood_count", "35", "Какое количество команд можно отправить в разрешенный период премени");
	cvar.AddChangeHook(CVarChangedf_CountCmd);
	iCountCmd = cvar.IntValue;
	
	AutoExecConfig(true, "limit_cmd");
	
	BuildPath(Path_SM, sFile, sizeof(sFile), "logs/limit_cmd.log");
}

public void CVarChanged_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnable	= cvar.BoolValue;
}

public void CVarChangedf_Flood(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fFloodCheck = cvar.FloatValue;
}

public void CVarChangedf_CountCmd(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iCountCmd = cvar.IntValue;
}

public void OnClientConnected(int client)
{
	iCountUse[client] = 0;
	bLogsSay[client] = false;
	
	hTimerFlood[client] = null;
	delete hTimerFlood[client];
}

public Action OnClientCommand(int client, int args)
{
	if(!bEnable)
		return Plugin_Continue;
		
	if(!(client || !IsFakeClient(client)))
		return Plugin_Continue;
	
	char sSteam[32], ip[16];
	GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
	GetClientIP(client, ip, sizeof(ip));
	
	if(fFloodCount[client] > GetGameTime() - fFloodCheck && iCountUse[client] >= iCountCmd)
	{
		KickClient(client, "[Anti-Flood] Вы привысили лимит спама команд !");
		if(!bLogsSay[client])
		{	
			bLogsSay[client] = true;
			LogToFile(sFile, "Игрок [%s] [%s] [%N] был кикнут за превышения лимита команда [%d] в [%.2f] секунд",
			ip, sSteam, client, iCountUse[client], fFloodCheck);
		}
		return Plugin_Handled;
	}
	else
	{
		if(!hTimerFlood[client])
		{
			hTimerFlood[client] = CreateTimer(fFloodCheck, UnTimeClient, GetClientUserId(client));
		}
		else
		{
			hTimerFlood[client] = null;
			delete hTimerFlood[client];
			hTimerFlood[client] = CreateTimer(fFloodCheck, UnTimeClient, GetClientUserId(client));
		}
	}
	
	iCountUse[client]++;
	fFloodCount[client] = GetGameTime();
	
	return Plugin_Continue;
}

public Action UnTimeClient(Handle timer, any client)
{
	if((client = GetClientOfUserId(client)))
    {
		iCountUse[client] = 0;
		hTimerFlood[client] = null;
	}
	return Plugin_Stop;
}