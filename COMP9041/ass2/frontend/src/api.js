// change this when you integrate with the real API, or when u start using the dev server
const API_URL = 'http://localhost:8080'
const API_DEV_URL = 'http://localhost:5000/'


function postData(path = ``, data = {}, token) {
    // Default options are marked with *
    let header = {
        'accept': 'application/json',
        'Content-Type': 'application/json'
    }
    if (token) {
        header['Authorization'] = 'Token '+token+''
    }
    let fetchOption = {
        method: "POST",
        headers: header,
        body: JSON.stringify(data)
    }
    return fetch(path, fetchOption)
}

function putData(path = ``, data = {}, token) {
    // Default options are marked with *

    let header = {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': token
    }
    if (token) {
        header['Authorization'] = 'Token '+token+''
    }
    let fetchOption = {
        method: "PUT",
        headers: header,
        body: JSON.stringify(data)
    }
    return fetch(path, fetchOption)
}

function deleteData(path = ``, data = {}, token) {
    // Default options are marked with *

    let header = {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': token
    }
    if (token) {
        header['Authorization'] = 'Token '+token+''
    }
    let fetchOption = {
        method: "DELETE",
        headers: header,
        body: JSON.stringify(data)
    }
    return fetch(path, fetchOption)
}

function getData(url, token) {
    let header = {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Token '+token+''
    }
    let fetchOption = {
        method: "GET",
        headers: header
    }
    return fetch(url, fetchOption)
}

const postJSON = (path, params, successCallback, failCallback, token) => postData(path, params, token)
    .then((resp) => {
        successCallback(resp)
        return resp
    })
    .catch( (error) => {
        failCallback(error)
        return error
        }
    );

const getJSON= (url, token, successCallback, failCallback) => getData(url ,token)
    .then((resp) => {
        successCallback(resp)
        return resp
    })
    .catch( (error) => {
        failCallback(error)
        return error
        }
    );

const putJSON = (path, params, successCallback, failCallback, token) => putData(path, params, token)
    .then((resp) => {
        successCallback(resp)
        return resp
    })
    .catch( (error) => {
            failCallback(error)
            return error
        }
    );

const deleteJSON = (path, params, successCallback, failCallback, token) => deleteData(path, params, token)
    .then((resp) => {
        successCallback(resp)
        return resp
    })
    .catch( (error) => {
            failCallback(error)
            return error
        }
    );
/**
 * This is a sample class API which you may base your code on.
 * You don't have to do this as a class.
 */
export default class API {

    /**
     * Defaults to teh API URL
     * @param {string} url 
     */
    constructor(url = API_URL,url2 = API_DEV_URL) {
        this.url = url;
        this.url2 = url2;
    } 

    makeAPIRequest(path) {
        return getJSON(`${this.url}/${path}`);
    }

    makeAPIPostRequest(path, params, successCallback, failCallback, token) {
        return  postJSON(`${API_DEV_URL}${path}`,params, successCallback, failCallback, token);
    }

    makeAPIGetRequest(url, token, successCallback, failCallback){
        return getJSON(`${API_DEV_URL}${url}`,token,successCallback, failCallback)
    }

    makeAPIPutRequest(url,params,  successCallback, failCallback,token){
        return putJSON(`${API_DEV_URL}${url}`,params, successCallback, failCallback, token);
    }
    makeQuery(path, token, params, successCallback, failCallback) {
        let url = `${path}?`
        for (let key in params) {
            url += key+'='+params[key]+'&';
        }

        url = url.substr(0, url.length-1);
        return this.makeAPIGetRequest(url,token,successCallback,failCallback);

    }

    makeAPIDeleteRequest(url,params,  successCallback, failCallback,token){
        return deleteJSON(`${API_DEV_URL}${url}`,params, successCallback, failCallback, token);
    }
    /**
     * @returns feed array in json format
     */
    getFeed() {
        return this.makeAPIRequest('feed.json');
    }

    /**
     * @returns auth'd user in json format
     */
    getMe() {
        return this.makeAPIRequest('me.json');
    }

    sendLoginRequest(email, pw, success, fail) {
        let param = {
            "username": email,
            "password": pw
        }
        let result= this.makeAPIPostRequest('auth/login',param,success,fail);
        return result;
    }

    sendRegisterRequest(username, password, email, name,success, fail){
        let param = {
            "username": username,
            "password": password,
            "email": email,
            "name": name
        }
        let result = this.makeAPIPostRequest('auth/signup',param,success,fail);
        return result;
    }

    getFeedRequest(p, n, token,success,fail){
        let params = {
            'p': p,
            'n': n
        };

        return this.makeQuery('user/feed',token, params, success,fail)

    }

    getPostById(postId,token,success, fail){
        let params = {
            'id': postId
        };

        return this.makeQuery('post',token, params, success,fail)
    }

    getUser(params, token, success, fail){
        return this.makeQuery('user',token,params, success,fail)
    }

    likeAPost(postId,token,success, fail ){
        return this.makeAPIPutRequest('post/like?id='+postId,{},success,fail,token);
    }

    undoLikeAPost(postId,token,success, fail){
        return this.makeAPIPutRequest('post/unlike?id='+postId,{},success,fail,token);
    }

    getPostByPostId(postId,token, success, fail){
        return this.makeQuery('post?id='+postId,token,success,fail)
    }

    updateUserProfile(params,token, success, fail){
        return this.makeAPIPutRequest('user', params, success,fail,token)
    }

    postAnImage(params, token, success, fail) {
        let url = 'post';
        return this.makeAPIPostRequest(url, params, success, fail,token);
    }

    updateAnImage(params, token, success, fail,postId) {
        let url = 'post';
        if (postId) {
            url = 'post/?id='+postId
        }
        return this.makeAPIPutRequest(url, params, success, fail,token);
    }

    deleteAPost(id,params, token, success, fail) {
        return this.makeAPIDeleteRequest('post/?id='+id, params, success, fail,token);
    }

    followUser(username, token, success, fail) {
        let url = 'user/follow?username='+username;

        return this.makeAPIPutRequest(url, {}, success, fail,token);
    }

    unFollowUser(username, token, success, fail) {
        let url = 'user/unfollow?username='+username;
        return this.makeAPIPutRequest(url, {}, success, fail,token);
    }
}
