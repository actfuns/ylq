-- ./excel/npc/dialog_animation_config.xlsx
return {

    [10011] = {
        alway_feceto_hero = 0,
        command = "1,faceto,0|2,say,100,问世间，请为何物，只叫人生死相许！|5,say,100,我的官郎，你如今在何方...|11,faceto,235|12,say,100,???|18,faceto,180|22,faceto,235|25,say,100,不要...|26,faceto,180|26,say,100,停...|29,say,100,...|33,faceto,235|34,say,100,小面妹妹，其实...|43,faceto,180|45,say,100,其实他不是我的那个官郎",
        delay = 0,
        distance = 0,
        group = "g,5041|g,5042|g,5043",
        id = 10011,
        interval_time = 0,
        loop = 1,
        total_time = 50,
        type = 1,
    },

    [10012] = {
        alway_feceto_hero = 0,
        command = "1,pos,9999,9999|8,visible,1|8,pos,13.9,13.8|9,runto,15.5,15.0|10,say,100,天天姐姐，别难过，我帮抓到了这个负心汉了|14,faceto,135|15,say,100,渣男，出来吧|21,say,100,渣男，还不承认错误?看我今天怎么教训你!!!|24,say,100,吃我一招，淑女夺命枪|25,action,attack1,none,0|26,action,idleCity,0|33,faceto,45|35,say,100,天天，姐姐，你不用谢我，我只是为天下的可怜女人出口气|38,say,100,我还有事，我先走了|40,runto,13.9,13.8|41,pos,9999,9999",
        delay = 0,
        distance = 0,
        group = "g,5041|g,5042|g,5043",
        id = 10012,
        interval_time = 0,
        loop = 1,
        total_time = 50,
        type = 1,
    },

    [10013] = {
        alway_feceto_hero = 0,
        command = "1,pos,9999,9999|17,pos,18.0,14.5|17,action,idleCity,none,0|17,faceto,-45|18,say,100,面美女，我到底做错了什么，你把我抓来这里！！！|25,action,die,none,0|28,pos,9999,9999",
        delay = 0,
        distance = 0,
        group = "g,5041|g,5042|g,5043",
        id = 10013,
        interval_time = 0,
        loop = 1,
        total_time = 50,
        type = 1,
    },

    [20001] = {
        alway_feceto_hero = 1,
        command = "1,say,100,汪汪汪|1,voice,UI/ui_sound_006.wav",
        delay = 0,
        distance = 2,
        group = "",
        id = 20001,
        interval_time = 2,
        loop = 1,
        total_time = 5,
        type = 2,
    },

}
