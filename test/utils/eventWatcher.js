
const eventWatcher = (contract, event) => {
    return new Promise((resolve, reject) => {
      try{
        contract.once(event, (...res) => resolve(res))
      }catch(e){
        reject(e);
      }
    })
  }
  
  
  module.exports = eventWatcher
    
  