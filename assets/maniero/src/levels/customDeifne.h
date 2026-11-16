#pragma once

//=============================================================================
// CORE / GENERIC
//=============================================================================
#define OOOO                                     0
#define BASE_SCORE                               0
#define LIVES                                    3
#define LEVEL_START                              0
#define LEVEL_COUNT                              6
#define MAX_LEVEL                               10
#define LAST_LEVEL                               7

//=============================================================================
// SCORE
//=============================================================================
#define ENEMY_KILL_SCORE                        50
#define COIN_SCORE                             100
#define COIN_TILE_SCORE                         10

//=============================================================================
// PHYSICS
//=============================================================================
#define GRAVITY_ACC                              1
#define JUMP_FORCE                               7
#define MAX_FALL_DISTANCE  (PLAYER_H * 4)
#define SMOOTHING_FACTOR                         2
#define TOL_Y                                    8

//=============================================================================
// PLAYER
//=============================================================================
#define PLAYER_W                                16
#define PLAYER_H                                16
#define PLAYER_START_X                          15
#define PLAYER_START_Y                         168

#define PLAYER_MOVE_ANIM_SPEED                   1
#define PLAYER_LEFT_SPRITE_BASE                  8
#define PLAYER_RIGHT_SPRITE_BASE                 0
#define PLAYER_SPRITE_NUM                        0

// Idle
#define IDLE_DELAY_FRAMES                 (60 * 3)
#define IDLE_ANIM_SPEED                         12
#define IDLE_SPRITE_BASE                        16
#define IDLE_NUM_FRAME                           5

//=============================================================================
// BULLETS
//=============================================================================
#define MAX_BULLET                               1
#define BULLETS                                  0
#define BULLET_SPEED                             2
#define BULLET_MAX_DISTANCE                     80
#define BULLET_SPRITE_INDEX                      1
#define BULLET_SPRITE_BASE                      16
#define BULLET_SPRITE_SPAN                      10

//=============================================================================
// ENEMIES
//=============================================================================
#define MAX_ENEMY                               14
#define FIRST_ENEMY_SPRITE_INDEX                 7

#define ENEMY_ANIM_FIRST_FRAME_RIGHT            26
#define ENEMY_ANIM_FIRST_FRAME_LEFT             32
#define ENEMY_ANIM_FRAME_COUNT                   6
#define ENEMY_ANIM_SPEED                         8
#define BASE_FRAME_ENEMY                         0

// Tipi specifici
#define ENEMY_DOCTOR_ANIM_FIRST_FRAME_RIGHT     64
#define ENEMY_DOCTOR_ANIM_FIRST_FRAME_LEFT      (ENEMY_DOCTOR_ANIM_FIRST_FRAME_RIGHT + 8)

#define ENEMY_POLICEMAN_ANIM_FIRST_FRAME_RIGHT  80
#define ENEMY_POLICEMAN_ANIM_FIRST_FRAME_LEFT   (ENEMY_POLICEMAN_ANIM_FIRST_FRAME_RIGHT + 8)

#define ENEMY_WORKER_ANIM_FIRST_FRAME_RIGHT    112
#define ENEMY_WORKER_ANIM_FIRST_FRAME_LEFT     (ENEMY_WORKER_ANIM_FIRST_FRAME_RIGHT + 8)

#define ENEMY_MILITARY_ANIM_FIRST_FRAME_RIGHT   26
#define ENEMY_MILITARY_ANIM_FIRST_FRAME_LEFT    (ENEMY_MILITARY_ANIM_FIRST_FRAME_RIGHT + 8)

#define BASE_FRAME_ENEMY_UP_DOWN               128

// Hit
#define ENEMY_HIT_FIRST_FRAME                   16
#define ENEMY_HIT_FRAMES                         4
#define ENEMY_HIT_SPEED                          6

//=============================================================================
// ENEMY AI
//=============================================================================
#define UPDATE_ENEMY_AI                         4
#define AI_BUDGET_PER_FRAME                     1

#define AI_TYPE_PATROL                          0
#define AI_TYPE_SLEEPER                         2
#define AI_TYPE_COWARD                          3
#define AI_TYPE_JUMPER                          4
#define AI_TYPE_TELEPORTER                      5
#define AI_TYPE_LEADER                          6
#define AI_TYPE_FOLLOWER                        7
#define AI_TYPE_SIGNALMAN                       8

#define HIDDEN_TIMER_RESET                    600

//=============================================================================
// COINS
//=============================================================================
#define MAX_COINS                                5
#define FIRST_COIN_SPRITE_INDEX                  2

#define COIN_ANIM_FIRST_FRAME                   21
#define COIN_ANIM_FRAME_COUNT                    4
#define COIN_ANIM_SPEED                          8

#define COIN_PICKUP_FIRST_FRAME                 16
#define COIN_PICKUP_FRAMES                       4
#define COIN_PICKUP_SPEED                        6

#define COIN_BASE_PATTERN                       16
#define COIN_FRAMES                              4

//=============================================================================
// BLOCKS / OBJECTS
//=============================================================================
#define MAX_BLOCK                                5
#define FIRST_BLOCK_SPRITE_INDEX   (FIRST_ENEMY_SPRITE_INDEX + MAX_ENEMY)
#define FIRST_ANIM_SPRITE_INDEX                 62

//=============================================================================
// MAP / TILE SYSTEM
//=============================================================================
#define TILE_SIZE                                8
#define TILE_MAX                              1024
#define MAX_TILE_NUMBER                       300

#define MAP_WIDTH                               64
#define MAP_HEIGHT                              27

// Tile speciali
#define TILE_WOOD_START                          8
#define TILE_WOOD_END                           13
#define TILE_ICE_START                          84
#define TILE_ICE_END                            87
#define TILE_SAND_START                         88
#define TILE_SAND_END                           91
#define TILE_LAWN_START                          2
#define TILE_LAWN_END                            3

#define TILE_OVERLAY_START                      70
#define TILE_OVERLAY_END                       110

// Tile counts
#define MAX_TILE_COINS                         30
#define MAX_TILE_KEYS                           2
#define MAX_TILE_HEART                          1

//=============================================================================
// GROUND TYPES
//=============================================================================
#define GROUND_NORMAL                           0
#define GROUND_SLOW                             0
#define GROUND_VERY_SLOW                        0

//=============================================================================
// CAMERA / SCROLLING
//=============================================================================
#define MAX_SCROLLING                          255
#define MIN_SCROLLING                            1

#define CAMERA_DEADZONE_LEFT                    80
#define CAMERA_DEADZONE_RIGHT                  176
#define CAMERA_SPEED                             2

//=============================================================================
// SPRITES / SYSTEM LIMITS
//=============================================================================
#define MAX_SPRITE                             125
#define MAX_PAWN                                 1

//=============================================================================
// AUDIO
//=============================================================================
#define AUDIO_UPDATE_INTERVAL                   1

//=============================================================================
// OVERLAY
//=============================================================================
#define OVERLAY_COUNT_MANIERO                   6

//=============================================================================
// FEATURE FLAGS
//=============================================================================
#define ENABLE_PLAYER_DEPTH                     0
#define ENABLE_PLAYER_WAS_FALLING               0
#define ENABLE_LADDER_MANAGEMENT                1
#define ENABLE_BULLET_MANAGEMENT                1
#define ENABLE_DOOR                             1

// AI enable
#define ENABLE_AI_TYPE_PATROL                   1
#define ENABLE_AI_TYPE_SLEEPER                  0
#define ENABLE_AI_TYPE_COWARD                   0
#define ENABLE_AI_TYPE_JUMPER                   0
#define ENABLE_AI_TYPE_TELEPORTER               0
#define ENABLE_AI_TYPE_LEADER                   0
#define ENABLE_AI_TYPE_FOLLOWER                 0
#define ENABLE_AI_TYPE_SIGNALMAN                0


//=============================================================================
// MESSAGE
//=============================================================================
#define INTRO_GAME                              0
#define GAME_OVER                               1

// Costanti message ID (da includere nel tuo header principale)
#define MSG_INTRO_GAME  0
#define MSG_GAME_OVER   1
#define MSG_GAME_WIN    2
#define MSG_MENU_MAIN   3
#define MSG_CREDITS     4