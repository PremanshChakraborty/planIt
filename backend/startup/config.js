const config = require('config');
module.exports = function(){
    
    if(!config.get('dbKey')) {
        throw new Error('FATAL ERROR : jwtPrivateKey is not defined');
    }
}