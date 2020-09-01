// 删除数据库js脚本

function IsFilterDB(sDBName) {
    var filterList = ["local", "admin",];
    for(i = 0; i < filterList.length; i++) {
        if(sDBName == filterList[i])
            return true;
    }
    return false;
}

function FilterDB(res) {
    var dbList = res["databases"];
    var dropList = [];
    for(var i = 0; i < dbList.length; i++) {
        var sDBName = dbList[i]["name"];
        if(IsFilterDB(sDBName))
            continue;
        dropList.push(sDBName);
    }
    return dropList;
}

function DropDB(dropList) {
    for(var i = 0; i < dropList.length; i++) {
        print("dropDatabase ",dropList[i]);
        tmpdb = db.getSisterDB(dropList[i]);
        tmpdb.dropDatabase();
    }
}

function GetDropDBs() {
    var res = db.getMongo().getDBs();
    var dropList = FilterDB(res);
    return dropList;
}

function DropDBs() {
    var dropList = GetDropDBs();
    DropDB(dropList);
}

