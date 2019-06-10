const std = @import("std");
const redis = @cImport({
    @cInclude("stdarg.h");
    @cInclude("./lib/redismodule.h");
});

// SETNE key val
export fn SETNE(ctx: ?*redis.RedisModuleCtx, argv: [*c]?*redis.RedisModuleString, argc: c_int) c_int {
    if (argc < 3) return redis.RedisModule_WrongArity.?(ctx);

    // Obtain pointer & length of the `val` argument
    var val_len: usize = undefined;
    var val = redis.RedisModule_StringPtrLen.?(argv[2], &val_len)[0..val_len];

    // Obtain the key from Redis (in a block so that defer happens before the next stage).
    {
        var key = @ptrCast(?*redis.RedisModuleKey, redis.RedisModule_OpenKey.?(ctx, argv[1], redis.REDISMODULE_READ));
        defer redis.RedisModule_CloseKey.?(key);

        // If the key is a string, check its value before proceeding.
        var keyType = redis.RedisModule_KeyType.?(key);
        if (keyType == redis.REDISMODULE_KEYTYPE_STRING){
            var key_strlen: usize = undefined;
            var key_string = redis.RedisModule_StringDMA.?(key, &key_strlen, redis.REDISMODULE_READ)[0..key_strlen];
            if (std.mem.eql(u8, val, key_string)) return redis.RedisModule_ReplyWithSimpleString.?(ctx, c"OK");
        }   
    }

    // Set the string using the high-level API. All args get routed to the native SET command.
    var reply = redis.RedisModule_Call.?(ctx, c"SET", c"v", &(argv[1]), argc - 1);
    return redis.RedisModule_ReplyWithCallReply.?(ctx, reply);
}


export fn RedisModule_OnLoad(ctx: *redis.RedisModuleCtx, argv: [*c]*redis.RedisModuleString, argc: c_int) c_int {
    if (redis.RedisModule_Init(ctx, c"kristoff-it/setne", 1, redis.REDISMODULE_APIVER_1) == redis.REDISMODULE_ERR) {
        return redis.REDISMODULE_ERR;
    }
    
    const err = redis.RedisModule_CreateCommand.?(ctx, c"setne", SETNE, c"write deny-oom", 1, 1, 1);
    if (err == redis.REDISMODULE_ERR) return redis.REDISMODULE_ERR;
    
    return redis.REDISMODULE_OK;
}
