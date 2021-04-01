//////////////////////////////////////////////////////////////////////////////////
// File Name: 		RVS192_user_parameters.sv
// Module Name:		RVS192 configurable parameters		
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

package	RVS192_user_parameters;

	parameter	CACHE_BLOCK_SIZE = 64;	
	parameter	ICACHE_LINE = 128;				//	32KB
// 	parameter 	ICACHE_BLOCK_SIZE = 32;
	parameter	ICACHE_WAY = 2;
	parameter	DCACHE_LINE = 32;				//	32KB
//	parameter	DCACHE_BLOCK_SIZE = 64;
	parameter	DCACHE_WAY = 4;
	parameter 	DCACHE_WB_DEPTH = 10;
	parameter	L2_CACHE_LINE = 64;
//	parameter	L2_CACHE_BLOCK_SIZE = 64;
	parameter 	L2_CACHE_WAY = 8;
	parameter 	L2_CACHE_WB_DEPTH = 16;
	parameter	GSHARE_HISTORY_LENGTH = 12;
	parameter 	LOCAL_HISTORY_LENGTH = 10;
	parameter	GSHARE_GPT_INDEX = 10;
	parameter 	LOCAL_LPT_INDEX = 10;
	parameter 	LOCAL_LHT_INDEX = 12;
	parameter 	BTB_INDEX = 8;
	parameter 	BTB_TAG_LENGTH = 30-BTB_INDEX;

endpackage