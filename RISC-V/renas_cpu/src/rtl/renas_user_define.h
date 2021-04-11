//////////////////////////////////////////////////////////////////////////////////
// File Name: 		RVS192_user_define.h
// Module Name:		User Define 		
// Project Name:	RVS192
// Author:	 		hungbk99
// University:     	DP S192	HCMUT
//////////////////////////////////////////////////////////////////////////////////

	`define	INST_VICTIM_CACHE;
	`define	DATA_VICTIM_CACHE;
	
//	define 1 in 2	
//	`define ICACHE_ALRU;
	`define ICACHE_RANDOM;

//	define 1 in 2
//	`define DCACHE_ALRU;
	`define DCACHE_RANDOM;

//	define 1 in 3
	`define HYBRID_BP;
//	`define GSHARE_BP;
//	`define LOCAL_BP;
	`define SIMULATE
