var ZoneFileData = []
console.log("Enumerating dns zone records...")
$('.mat-row').each(function(i, obj) {
    console.log(" |-Record Number [" + i + "]")
    var RecordDetails = $($(obj).first()).first().text()
    var rType = RecordDetails.split(' ')[0]
    var rName = RecordDetails.split(' ')[3]
    var rValue = RecordDetails.split(' ')[5]
    var rTTLHours = RecordDetails.split(' ')[7]
    console.log(" |  |-Type = " + rType)
    console.log(" |  |-Name = " + rName)
    console.log(" |  |-Value = " + rValue)
    console.log(" |  |-TTL = " + rTTLHours)
    console.log(" |  \\")
    var RecordData = {
       "Type": rType,
       "Name": rName,
       "Value": rValue,
       "TTL": rTTLHours
    }
    ZoneFileData.push(RecordData)
});
console.log(" \\")
JSON.stringify(ZoneFileData)