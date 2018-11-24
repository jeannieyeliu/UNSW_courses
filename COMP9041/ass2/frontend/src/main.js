import {
    setLocalStorageItem,
    checkStore,
    removeLocalStorageItem,
    newNode,
    addChild,
    setContent,
    removeNode,
    getContent,
    getAttr,
    setAttr,
    addListener,
    addClass,
    removeClass,
} from './helpers.js';

// when importing 'default' exports, use below syntax
import API from './api.js';

const api = new API();

// ----------- check status begin -----------------
let token = checkStore('AUTH_KEY');
function doNothing() {}
function showSignUp() {
    addClass(['.login-block', '.main-index-block', '.main-index-block-main', '.banner', '.user-profile'], 'disappear');
    removeClass('.register-block', 'disappear');
}

function showLogin() {
    addClass(['.register-block', '.main-index-block', '.main-index-block-main', '.banner', '.user-profile'], 'disappear');
    removeClass('.login-block', 'disappear');
}

function showProfilePage() {
    addClass(['.register-block', '.main-index-block-main', '.login-block',], 'disappear');
    removeClass(['.user-profile','.main-index-block','.banner'], 'disappear');
    document.getElementById('my-profile').style.display = 'none';
    document.getElementById('go-back-btn').style.display= '';
}

function loadMainPageCache() {
    addClass(['.register-block', '.login-block','.user-profile',], 'disappear');
    removeClass(['.main-index-block', '.main-index-block-main', '.banner'], 'disappear');
    document.getElementById('my-profile').style.display = '';
    document.getElementById('go-back-btn').style.display= 'none';
}

let loadStart = 0;
let loadOffset = 5;
let io;
function loadMainPage() {
    storeUserInfo()
    loadMainPageCache()
    removeNode('large-feed-sub');
    // the infinite scroll
    io = new IntersectionObserver((item) => {
            if (item[0].intersectionRatio <= 0) return;
            console.log('see footer');
            loadImage(loadStart, loadOffset, checkStore('AUTH_KEY'));
            loadStart += loadOffset;
        }
    );

    io.observe(document.getElementById('footer'));
}

function storeUserInfo() {
    let result = api.getUser('', checkStore('AUTH_KEY'), doNothing, doNothing);
    result.then(resp => resp.json()).then(
        respJson => {
            setLocalStorageItem('USER_ID', respJson['id']);
            setLocalStorageItem('USER_NAME', respJson['username']);
            setLocalStorageItem('NAME', respJson['name']);
            setLocalStorageItem('EMAIL', respJson['email']);
        }
    );
}

gotoFeed();
function gotoFeed() {
    token = checkStore('AUTH_KEY');
    if (token == null || token == '') {
        showLogin();
    } else {
        api.getUser('', checkStore('AUTH_KEY'), doNothing, doNothing)
            .then(resp => {
                if (resp.status != 200) {
                    showLogin();
                } else {
                    loadMainPage();
                }
            })
    }
}

// ----------- check status end -------------------
// ----------- login feature begin ---------------
async function succLogin(resp) {
    let respJson = await resp.json();
    switch (resp.status) {
        case 200:
            setLocalStorageItem('AUTH_KEY', respJson['token']);
            loadMainPage();
            break;
        case 400: case 403: default:
            removeClass('#login_err_msg','disappear');
            setContent('#login_err_msg','<p>' + respJson['message'] + '</p>')
            break;
    }
}

function clearLoginError() {
    document.querySelector('#login_err_msg').classList.add('disappear');
}

function login() {
    let username = document.querySelector("#login_username").value;
    let pw = document.querySelector("#login_password").value;
    api.sendLoginRequest(username, pw, succLogin, doNothing);
}

function logout() {
    removeLocalStorageItem('AUTH_KEY');
    removeNode('large-feed-sub');
    if(io){
        io.unobserve(document.getElementById('footer'));
        io.disconnect();
    }
    if (notifyInterval){
        clearInterval()
    }
    showLogin();
}

document.querySelector('#login_btn').addEventListener('click', login);
document.querySelector('#login_username').addEventListener('focus', clearLoginError);
document.querySelector('#login_password').addEventListener('focus', clearLoginError);
document.querySelector('#log_out_btn').addEventListener('click', logout);

// ----------- login feature end ---------------

// ----------- register feature begin ----------
function clearRegisterError() {
    document.querySelector('#register_err_msg').classList.add('disappear');
}

async function registerSuccess(resp) {
    let respJson = await resp.json();

    switch (resp.status) {
        case 200:
            setLocalStorageItem('AUTH_KEY', respJson['token']);
            loadMainPage();
            break;
        case 400 :
            document.querySelector('#register_err_msg').classList.remove('disappear');
            document.querySelector('#register_err_msg').innerHTML = '<p>' + respJson['message'] + '</p>';
            break;
        case 409:
            document.querySelector('#register_err_msg').classList.remove('disappear');
            document.querySelector('#register_err_msg').innerHTML = '<p> User already exists!</p>';
            break;
        default:
            break;
    }
}

function registerFail() {

}

function register() {
    let email = document.querySelector('#register_email').value;
    let name = document.querySelector('#register_name').value;
    let username = document.querySelector("#register_username").value;
    let pw = document.querySelector("#register_password").value;
    api.sendRegisterRequest(username, pw, email, name, registerSuccess, registerFail);

}

document.querySelector('#sign_up_from_log_in').addEventListener('click', showSignUp);
document.querySelector('#login_from_sign_up').addEventListener('click', showLogin);
document.querySelector('#sign_up_btn').addEventListener('click', register);
//addListener(['#register_email','#register_name','#login_username','#login_password'], clearRegisterError)
document.querySelector('#register_email').addEventListener('focus', clearRegisterError);
document.querySelector('#register_name').addEventListener('focus', clearRegisterError);
document.querySelector('#login_username').addEventListener('focus', clearRegisterError);
document.querySelector('#login_password').addEventListener('focus', clearRegisterError);
// ----------- register feature end ------------

function showModel(contentNode) {
    let modal = document.getElementById('myModal');
    let close = document.querySelector('.close');
    removeNode('.modal-info');
    let modalInfo = newNode({'tag': 'div', id: 'modal-info', class: 'modal-info modal-body', child: contentNode});
    document.querySelector('.modal-content').appendChild(modalInfo);
    modal.style.display = "block";
    close.onclick = function () {
        modal.style.display = "none";
    };
    window.onclick = function (event) {
        if (event.target == modal) {
            // modal.style.display = "none";
            hideModal()
        }
    }
}
function setModalTitle(title) {
    setContent('#modalTitle',title)
}


function hideModal() {
    document.getElementById('myModal').style.display = 'none';
}

async function processPostDetail(resp) {
    let respJson = await resp.json();
    let wholikesArray = respJson
}

function showLikes(e) {
    e = e || window.event;
    let target = e.target || e.srcElement;
    let whoLikes = target.title.split(',');

    showModel();
    setModalTitle('Who likes this post')
    let likesDiv = document.createElement('div');
    likesDiv.className = 'likesDiv';
    // let likesTitle = document.createElement('div');
    // likesTitle.className = 'likesTitle';
    // likesTitle.innerHTML = 'likes';
    // document.querySelector('#modal-info').appendChild(likesTitle);
    document.querySelector('#modal-info').appendChild(likesDiv);

    // fetch user
    for (let i in whoLikes) {
        let result = api.getUser({id: whoLikes[i]}, checkStore('AUTH_KEY'), doNothing, doNothing);
        result.then(resp => resp.json()).then(
            respJson => {
                likesDiv.innerHTML += '<p>' + respJson['username'] + '</p>'
            }
        )
    }

}

function likeAPost(e) {
    e = e || window.event;
    let target = e.target || e.srcElement;
    let postId = target.title;
    api.likeAPost(postId, token, doNothing, doNothing())
        .then(resp => {
            if (resp.status == 200) {
                target.removeEventListener('click', likeAPost);
                target.addEventListener('click', unlikeAPost);
                target.innerHTML = 'unlike it';
                let likeNum = parseInt(document.querySelector('#divImageWhoLikes' + postId).innerHTML.split(' ')[0]);
                likeNum++;
                document.querySelector('#divImageWhoLikes' + postId).innerHTML = likeNum + ' likes';
                let likesDiv = 0;
                if (likeNum == 1) {
                    document.querySelector('#divImageWhoLikes' + postId).setAttribute('title', checkStore('USER_ID'));
                    document.querySelector('#divImageWhoLikes' + postId).addEventListener('click', showLikes)
                } else {
                    let title = document.querySelector('#divImageWhoLikes' + postId).getAttribute('title');
                    title = title + ',' + checkStore('USER_ID');
                    document.querySelector('#divImageWhoLikes' + postId).setAttribute('title', title)
                }
            }
        })


}

function unlikeAPost(e) {
    e = e || window.event;
    let target = e.target || e.srcElement;
    let postId = target.title;

    api.undoLikeAPost(postId, checkStore('AUTH_KEY'), doNothing, doNothing)
        .then(resp => {
            if (resp.status == 200) {
                target.removeEventListener('click', unlikeAPost);
                target.addEventListener('click', likeAPost);
                target.innerHTML = 'like it';
                let likeNum = parseInt(document.querySelector('#divImageWhoLikes' + postId).innerHTML.split(' ')[0]);
                likeNum--;
                document.querySelector('#divImageWhoLikes' + postId).innerHTML = likeNum + ' likes';
                if (likeNum == 0) {
                    document.querySelector('#divImageWhoLikes' + postId).removeEventListener('click', showLikes)
                }

                let title = document.querySelector('#divImageWhoLikes' + postId).getAttribute('title').split(',');
                let index = title.indexOf(checkStore('USER_ID'));
                title.splice(index, 1);
                document.querySelector('#divImageWhoLikes' + postId).setAttribute('title', title.toString())
            }
        })
}

function deleteAPost(e) {

    e = e || window.event;
    let target = e.target || e.srcElement;
    let postId = target.getAttribute('arg');
    api.deleteAPost(postId, {}, checkStore('AUTH_KEY'), doNothing, doNothing)
        .then(resp => {
            if (resp.status == 200) {
                alert('Successfully delete the image.');
                removeNode('#divUserPost-sub' + postId);
            } else {
                alert('Fail to delete this image. Please try again later!')
            }
        })
}

function updateAPost(e) {
    e = e || window.event;
    let target = e.target || e.srcElement;
    let postId = target.getAttribute('arg');
    openLoadImageModal(postId);
}

function addPic(pic, parentId, isMe) {
    let id = pic['id'];
    let comments = pic['comments'];
    let author = pic['meta']['author'];
    let description_text = pic['meta']['description_text'];
    let likes = pic['meta']['likes'];
    let published = pic['meta']['published'];
    let src = pic['src'];
    let thumbnail = pic['thumbnail'];
    let userId = checkStore('USER_ID');
    let youLikeThisPost = likes.toString().split(',').indexOf("" + userId);

    let image = new Image();
    image.src = 'data:image/png;base64,' + src;
    image.width = 498;

    let thumbImage = new Image();
    thumbImage.src = 'data:image/png;base64,' + thumbnail;
    thumbImage.width = 30;


    let divImageAuthorAvatar = newNode({
        tag: 'div',
        class: 'divImageAuthorAvatar',
        id: 'divImageAuthorAvatar' + id,
        child: thumbImage,
        arg: author
    });

    let divImageAuthor = newNode({
        tag: 'div', class: 'divImageAuthor', id: 'divImageAuthor' + id, child: divImageAuthorAvatar,
        arg: author,
    });

    let divAuthorName = newNode({
        tag: 'a',
        class: 'divAuthorName',
        id: 'divAuthorName' + id,
        arg: author,
        innerHTML: author,
        parentNode: divImageAuthor

    });

    if(parentId != 'divUserPost')
        setAttr(divAuthorName, 'href', '#/profile='+author);
    else
        divAuthorName.onclick = doNothing
    //innerHTML: '<a href="#/profile=' + author + '">' + author + '</a>',

    let divImageItself = newNode({tag: 'div', class: 'divImageItself', id: 'divImageItself' + id, child: image});
    let divImagePostOption = newNode({tag: 'div', class: 'divImagePostOption', id: 'divImagePostOption' + id});

    let likeOption = newNode({
        tag: 'button',
        class: 'likeOption btn btn-outline-dark btn-sm',
        id: 'likeOption' + id,
        title: id,
        parentNode: divImagePostOption
    });


    if (youLikeThisPost >= 0) {
        likeOption.innerText = 'unlike it';
        likeOption.addEventListener('click', unlikeAPost);
    }
    else {
        likeOption.innerText = 'like it';
        likeOption.addEventListener('click', likeAPost);
    }

    if (isMe) {
        let deleteOption = newNode({
            tag: 'button', class: 'deleteOption btn btn-outline-dark btn-sm', id: 'deleteOption' + id, arg: id, parentNode: divImagePostOption,
            innerHTML: 'delete',
            listener: {
                event: 'click',
                func: deleteAPost
            }
        });

        let updateOption = newNode({
            tag: 'button', class: 'updateOption btn btn-outline-dark btn-sm', id: 'updateOption' + id, arg: id, parentNode: divImagePostOption,
            innerHTML: 'update',
            listener: {
                event: 'click',
                func: updateAPost
            }
        });
    }

    let divImageLikes = newNode({
        tag: 'div',
        class: 'divImageLikes',
        id: 'divImageLikes' + id,
        title: id,
        parentNode: divImagePostOption
    });
    let likeNum = likes.length;

    let divImageWhoLikes = newNode({
        tag: 'a', class: 'divImageWhoLikes', id: 'divImageWhoLikes' + id,
        title: '', innerHTML: likeNum + ' likes', parentNode: divImageLikes
    });

    if (likeNum != 0) {
        divImageWhoLikes.onclick = showLikes;
        divImageWhoLikes.title = likes.toString();
    }

    let divImageDesp = newNode({
        tag: 'div', class: 'divImageDesp', id: 'divImageDesp' + id, title: id,
        innerHTML: description_text, parentNode: divImagePostOption
    });

    let divImageComments = newNode({
        tag: 'div', class: 'divImageComments', id: 'divImageComments' + id, title: id,
        innerHTML: ''
    });

    for (let i in comments) {
        let commentAuthor = comments[i]['author'];
        let commentPublished = comments[i]['published'];
        let commentContent = comments[i]['comment'];

        console.log(comments[i], commentAuthor, commentPublished);
        let divComment = newNode({
            tag: 'p', class: 'divImageLikes', id: 'divComment-' + id + '-' + 'commentPublished',
            parentNode: divImageComments
        });
        document.createElement('p');
        divComment.innerHTML = '<p><span class="commentAuthor">' + commentAuthor +
            ':</span> <span class="commentContent">' + commentContent +
            '</span></p>'
    }

    let divImageCommentInput = newNode({
        tag: 'div', class: 'divImageCommentInput', id: 'divImageCommentInput' + id, title: id,
        innerHTML: ''
    });

    let divInput = newNode({
        tag: 'input', id: 'divInput' + id, placeholder: 'Add a comment...', arg: id,
        parentNode: divImageCommentInput,
        listener: {
            event: 'onblue',
            func: function (e) {
                e = e || window.event;
                let target = e.target || e.srcElement;
                target.value = '';
                //let postId = target.getAttribute('arg')
            }
        },
    });
    divInput.addEventListener('keyup', function (e) {
        e = e || window.event;
        if (e.keyCode == 13) {
            //TODO post api, addChild to
            console.log('post a comment!', e.target.value);
            let curr_comment = e.target.value;
            let postId = e.target.getAttribute('arg');
            let publish = new Date().getTime() / 1000;
            api.makeAPIPutRequest('post/comment?id=' + postId, {author: '', comment: curr_comment, published: publish},
                doNothing, doNothing, checkStore('AUTH_KEY'))
                .then(resp => {
                    if (resp.status == 200) {
                        let divCommentNew = newNode({
                            tag: 'p', class: 'divImageLikes', id: 'divComment-' + id + '-' + publish,
                            parent: 'divImageComments' + postId
                        });
                        divCommentNew.innerHTML = '<p><span class="commentAuthor">' + checkStore('USER_NAME') +
                            ':</span> <span class="commentContent">' + curr_comment +
                            '</span></p>';
                        e.target.blur();
                        e.target.value = '';
                    }
                });
        }
    });


    //     <input id="login_username" placeholder="Enter your username" autocomplete>
    let largeFeedSub = document.getElementById('largeFeedSub');
    if (largeFeedSub == null) {
        largeFeedSub = newNode({tag: 'div', class: parentId + '-sub', id: parentId + '-sub' + id, parent: parentId});
    }


    let divBelowImage = newNode({tag: 'div', class: 'divBelowImage', id: 'divBelowImage' + id,
        childList: [divImagePostOption, divImageLikes, divImageDesp, divImageComments, divImageCommentInput]
    });

    let divImageOut = newNode({
        tag: 'div', class: 'divImageOut', id: 'divImageOut' + id, parentNode: largeFeedSub,
        childList: [divImageAuthor, divImageItself, divBelowImage]
    });

}

let notifyInterval;
async function feedSuccess(resp) {
    let respJson = await resp.json();

    for (let i = 0; i < respJson['posts'].length; i++) {
        let pic = respJson['posts'][i];
        addPic(pic, 'large-feed');

        // console.log('try to start notification service!')
        if (!notifyInterval && i === 0 ) {
            setLocalStorageItem('LOAD_START', respJson['posts'][i]['id']);
            notifyInterval = setInterval(notify, 5000);
        }
    }
}

function notify() {
    api.getFeedRequest(0, 1, checkStore('AUTH_KEY'), doNothing, doNothing)
        .then(resp => resp.json())
        .then(respJson=>{
            let postId = respJson['posts'][0]['id'];
            if(checkStore('LOAD_START') != postId){
                new Notification('You have new posts from the users that you follow.')
                setLocalStorageItem('LOAD_START', postId);
            }
        }).catch(error=>console.log(error));

}


function feedFail() {

}

function loadImage(p, n, token) {
    api.getFeedRequest(p, n, token, feedSuccess, feedFail);

}

function loadImage2(token) {
    api.getFeedRequest(loadStart, loadStart + loadOffset, token, feedSuccess, feedFail);
    loadStart += loadOffset;
}

//------------ main page end -------------------

//------------ user profile begin --------------
function showFollowers(e) {
    e = e || window.event;
    let target = e.target || e.srcElement;
    let userId = target.title;
    let token = checkStore('AUTH_KEY');
    console.log("TODO: fetch followers by userId" + userId);
    if (target.title == '') {
        return;
    }
    let whoFollows = target.title.split(',');
    console.log('whoFollows');
    console.log(whoFollows);
    showModel();

    // let divFollowsTitle = newNode({
    //     tag: 'div',
    //     class: 'divFollowsTitle',
    //     id: 'divFollowsTitle',
    //     innerHTML: 'who is being followed ',
    //     parent: 'modal-info'
    // });

    setModalTitle('Followed')

    let divFollows = newNode({
        tag: 'div',
        class: 'followsDiv',
        id: 'followsDiv',
        parent: 'modal-info'
    });

    // fetch user
    for (let i in whoFollows) {
        let result = api.getUser({id: whoFollows[i]}, checkStore('AUTH_KEY'), doNothing, doNothing);
        result.then(resp => resp.json()).then(
            respJson => {
                let username = respJson['username']
                let line = newNode({tag: 'p', parentNode: divFollows, id: 'line-' + username, arg: username});
                newNode({
                    tag: 'span',
                    innerHTML: '<span>' + username + '</span>',
                    parentNode: line,
                });
                let unfollowBtn = newNode({
                    tag: 'button',
                    innerHTML: 'unfollow',
                    class:'btn btn-outline-dark btn-sm unfollow-btn',
                    parentNode: line,
                    arg: username,
                    arg2: whoFollows[i],
                    listener:{
                        event: 'click',
                        func: unfollowOther
                    }
                });

                // divFollows.innerHTML += '<p>' + respJson['username'] + '</p>'
            }
        )
    }
}

function showUserProfile(e) {
    e = e || window.event;
    let target = e.target || e.srcElement;
    let user_name;
    if (target.id == 'my-profile' || target.id == 'my-profile-a') {
        user_name = checkStore('USER_NAME');
    }
    else {
        user_name = target.getAttribute('arg');
        console.log(target);
        console.log(target.arg)
        if (user_name === 'me') {
            user_name = checkStore('USER_NAME');
        }
    }
    let isMe = false;
    if (user_name == checkStore('USER_NAME')) {
        isMe = true;
    }
    let result = api.getUser({username: user_name}, checkStore('AUTH_KEY'), doNothing, doNothing);
    result.then(resp => resp.json()).then(
        respJson => {
            let divUserContent = document.getElementById('divUserContent');
            if (divUserContent) {
                divUserContent.parentNode.removeChild(divUserContent);
            }

            let userName = respJson['username'];
            let name = respJson['name'];
            let email = respJson['email'];
            let followNums = respJson['followed_num'];
            let following = respJson['following'];
            let followingNums = following.length;
            let postNum = respJson['posts'].length;
            let posts = respJson['posts'];
            let userId = respJson['id'];


            let editbtn = newNode({
                tag: 'button',
                innerHTML: 'Edit Profile',
                id: 'user-profile-edit-btn',
                class: isMe ? 'btn btn-outline-dark btn-sm' : 'disappear',
                listener: {
                    event: 'click',
                    func: isMe ? editProfile : doNothing
                }
            })

            removeNode('#divUserContent');
            divUserContent = newNode({
                tag: 'div',
                class: 'divUserContent',
                id: 'divUserContent',
                parent: 'user-profile',
                //innerHTML: divUserInnerHTML,
                childList: [
                    newNode({
                        tag: 'p',
                        id: 'user-profile-username',
                        innerHTML: '<span class="profile-content username">' + userName + ' </span>',
                        child: editbtn
                    }),

                    // newNode({
                    //     tag: 'p',
                    //     id: 'user-profile-email',
                    //     innerHTML: `<span class="profile-title email">Email: </span><span class="profile-content">${email} </span>`
                    // }),

                    newNode({
                        tag: 'span',
                        innerHTML: `<span class="profile-title" id="postSum"> ${postNum} </span><span class="profile-content"> posts </span>`
                    }),

                    newNode({
                        tag: 'span',
                        innerHTML: '<span class="profile-content" > ' + followNums + ' followers </span>',
                        title: following.toString()
                    }),

                    newNode({
                        tag: 'span',
                        innerHTML: `<span class="profile-title" id="number-of-following" title="${following.toString()}"> ${followingNums} </span><span class="profile-content"  id="followingNum" title="${following.toString()}"> followings</span>`,
                        listener: {
                            'event': 'click',
                            'func': showFollowers,
                        },
                        title: following.toString()
                    }),



                    newNode({
                        tag: 'span',
                        innerHTML: `<span class="profile-title" id="likeSum"> 0 </span><span class="profile-content"> likes </span></p>`
                    }),

                    newNode({
                        tag: 'p',
                        id: 'user-profile-name',
                        innerHTML: `<span class="profile-content name">${name} </span>`
                    }),

                    newNode({
                        tag: 'div',
                        class: 'separator',
                        child: newNode({ tag: 'div', class:'avatar-div', child: newNode({tag:'img',id:'avatar', class:'avatar'})})
                    })
                ],
            });
            setAttr('#avatar','src','images/5_q.jpg')


            let divUserPost = newNode({
                tag: 'div',
                id: 'divUserPost',
                class: 'divUserPost',
                //parentNode: divUserContent,
                parentNode: newNode({tag:'div',parentNode:divUserContent}),
            });

            let postPromises = [];

            for (let i = 0; i < posts.length; i++) {
                let onePost = api.getPostByPostId(posts[i], checkStore('AUTH_KEY'), doNothing, doNothing).then(
                    resp => {
                        return resp.json()
                    }
                );
                postPromises.push(onePost)

            }

            Promise.all(postPromises).then((values) => {
                //console.log(values)
                let likeSum = 0;
                for (let i = 0; i < values.length; i++) {
                    addPic(values[i], 'divUserPost', isMe);

                    likeSum += values[i]['meta']['likes'].length
                }
                setContent('#likeSum', likeSum)
            });

            showProfilePage();
        }
    )
}


function editProfile() {
    console.log('editProfile!!!');
    showModel();
    setModalTitle('change your profile')

    let divModalForm = newNode({tag: 'form', parent: 'modal-info', class:'form-control-file'});
    divModalForm.setAttribute('method', 'updateProfile');

    let divUsernameLable = newNode({tag: 'label', class: 'divUsernameLable', innerHTML: 'Name:', value: 'Name:'});
    let divUsernameInput = newNode({
        tag: 'input',
        id: 'divUsernameInput',
        class: 'divUsernameInput form-control',
        value: checkStore('NAME')
    });
    let divUsernameOuter = newNode({
        tag: 'div', id: 'divUsernameOuter', class: 'divUsernameOuter',
        childList: [divUsernameLable, divUsernameInput], parentNode: divModalForm
    });


    let divEmailLable = newNode({tag: 'label', class: 'divEmailLable', innerHTML: 'Email:', value: 'Email:'});
    let divEmailInput = newNode({
        tag: 'input',
        id: 'divEmailInput',
        class: 'divEmailInput form-control',
        value: checkStore('EMAIL')
    });
    let divEmailOuter = newNode({
        tag: 'div', id: 'divEmailOuter', class: 'divEmailOuter',
        childList: [divEmailLable, divEmailInput], parentNode: divModalForm
    });


    let divPasswordLable = newNode({
        tag: 'label',
        class: 'divPasswordLable ',
        innerHTML: 'Password:',
        value: 'Password:'
    });
    let divPasswordInput = newNode({tag: 'input', id: 'divPasswordInput', class: 'divPasswordInput form-control', value: ''});
    divPasswordInput.setAttribute('type', 'password');
    let divPasswordOuter = newNode({
        tag: 'div', id: 'divPasswordOuter', class: 'divPasswordOuter',
        childList: [divPasswordLable, divPasswordInput], parentNode: divModalForm
    });

    let divError = newNode({
        tag: 'div', class: 'disappear', id: 'modal-error-msg', parentNode: divModalForm,
        child: newNode({tag: 'span'})
    });
    divError.style.color = 'red';
    let divUpdateBtn = newNode({
        tag: 'button', class: 'divPostBtn btn btn-outline-dark btn-sm',
        innerHTML: 'update',
        type: 'button',
        listener: {
            event: 'click',
            func: updateProfile
        },
        //parentNode: divModalForm
        parentNode: newNode({tag:'div',class:'modal-footer',parentNode: divModalForm})
    })
}

async function updateProfile() {
    console.log('updateProfile');
    let name = document.getElementById('divUsernameInput').value;
    let email = document.getElementById('divEmailInput').value;
    let password = document.getElementById('divPasswordInput').value;
    console.log(name, email, password);
    let params = {
        name: name,
        email: email,
        password: password
    };
    api.updateUserProfile(params, checkStore('AUTH_KEY'), doNothing, doNothing)
        .then(resp => {
            postUpdateProfile(resp)
        })
}

async function postUpdateProfile(resp) {
    if (resp.status == 200) {
        let name = document.getElementById('divUsernameInput').value;
        let email = document.getElementById('divEmailInput').value;
        let password = document.getElementById('divPasswordInput').value;
        document.querySelector('#user-profile-name .profile-content').innerHTML = name;

        storeUserInfo(checkStore('AUTH_KEY'));
        hideModal();
    } else {
        let respJson = await resp.json();
        document.querySelector('#modal-error-msg').classList.remove('disappear');
        document.querySelector('#modal-error-msg span').innerHTML = '<p>' + respJson['message'] + '</p>';
    }
}

//document.querySelector('#my-profile').addEventListener('click', showUserProfile);
//------------- user- profile end-------------

//------------- upload image begin -----------
function openLoadImageModal(postId) {
    showModel();
    setModalTitle("Post an image!")
    let divModalForm = newNode({tag: 'form', parent: 'modal-info', class:'form-control-file'});
    divModalForm.setAttribute('method', 'uploadAnImage');

    let divLoadImageInputOuter = newNode({
        tag: 'div', id: 'divLoadImageInputOuter', class: 'divLoadImageInputOuter',
        parentNode: divModalForm
    });

    let divLoadImageLabel = newNode({
        tag: 'label', type: 'file', id: 'divLoadImageLabel',
        class:'btn btn-outline-dark btn-sm',
        parentNode: divLoadImageInputOuter,
        innerHTML: 'Choose an image'
    });
    divLoadImageLabel.setAttribute('for', 'divLoadImageInput');

    let divLoadImageNameLabel = newNode({
        tag: 'input', id: 'divLoadImageNameLabel',
        class:'divLoadImageNameLabel form-control',
        parentNode: divLoadImageInputOuter,
        innerHTML: 'No file Selected.'
    });
    divLoadImageNameLabel.setAttribute('readonly',true)
    let divLoadImageInput = newNode({
        tag: 'input', type: 'file', id: 'divLoadImageInput',
        class: 'disappear',
        parentNode: divLoadImageInputOuter,
        listener:{
            event: 'change',
            func: function () {
                setContent(divLoadImageNameLabel, this.value.slice(this.value.lastIndexOf('\\')+1));
                divLoadImageNameLabel.value =  this.value.slice(this.value.lastIndexOf('\\')+1);
            }
        }
    });


    let divLoadImageDespOuter = newNode({
        tag: 'div', id: 'divLoadImageDespOuter', class: 'divLoadImageDespOuter',
        parentNode: divModalForm
    });
    let divLoadImageDespLabel = newNode({
        tag: 'label', class: 'divLoadImageDespLabel', innerHTML: 'Description:',
        value: 'Description:', parentNode: divLoadImageDespOuter
    });
    let divLoadImageDespInput = newNode({
        tag: 'input', id: 'divLoadImageDespInput', class: 'divLoadImageDespInput form-control ',
        parentNode: divLoadImageDespOuter
    });

    let divPostBtn = newNode({
        tag: 'button', class: 'divPostBtn btn btn-outline-dark btn-sm', innerHTML: 'Post!',
        type: 'button',
        listener: {
            event: 'click',
            func: uploadAnImage
        },
        parentNode: newNode({tag:'div',class:'modal-footer',parentNode: divModalForm})
    });

    if (typeof postId == "string") {
        divPostBtn.setAttribute('postId', postId)
    }
}

function uploadAnImage(event) {
    const [file] = document.getElementById('divLoadImageInput').files;

    console.log(file);
    //bad data, let's walk
    const validFileTypes = ['image/jpeg', 'image/png', 'image/jpg'];
    const valid = validFileTypes.find(type => type === file.type);
    // if we get here we have a valid image
    if (!valid) {
        alert('only jpg/jpeg/png files accepted!');
        return
    }
    let desp = document.getElementById('divLoadImageDespInput').value;

    const reader = new FileReader();
    let postId = event.target.getAttribute('postId');
    reader.onload = (e) => {
        // do something with the data result
        const dataURL = e.target.result;
        // const image = createElement('img', null, { src: dataURL });
        // document.body.appendChild(image);
        console.log(typeof dataURL);
        console.log('image data:', dataURL.toString().replace());
        let base64 = dataURL.split(',')[1];

        console.log('base64', base64);
        let params = {
            "description_text": desp,
            "src": base64
        };

        let func = api.postAnImage;
        if (typeof postId) {
            func = api.updateAnImage;
        }
        console.log(func);
        if (typeof postId != 'string') {
            api.postAnImage(params, checkStore('AUTH_KEY'), doNothing, doNothing, postId).then(resp => {
                //resp.json()
                if (resp.status == 200) {
                    alert('Successfully upload the image. please go to your profile to see this image');
                    hideModal()
                } else {
                    alert('Fail to upload the image, please try again.')
                }
            });
        }
        else {
            api.updateAnImage(params, checkStore('AUTH_KEY'), doNothing, doNothing, postId).then(resp => {
                //resp.json()
                if (resp.status == 200) {
                    alert('Successfully update the image. please go to your profile to see this image');
                    hideModal();
                    console.log(postId);
                    document.querySelector('#divImageItself' + postId + ' img').setAttribute('src', dataURL);
                    document.querySelector('#divImageDesp' + postId).innerHTML = desp;

                } else {
                    alert('Fail to upload the image, please try again.')
                }
            });

        }

    };

    // this returns a base64 image
    reader.readAsDataURL(file);
}

document.querySelector('#upload-image').addEventListener('click', openLoadImageModal);
//-------------- upload image end ---------

//--------------- follow a user begin ------

//document.querySelector('#follow-user-input-btn').addEventListener('click', followOther);
//addListener('#follow-user-input','keyUp', followOther)
document.querySelector('#follow-user-input').addEventListener('keyup', followOther);
function clearFollowError() {

    document.getElementById('follow-error').innerHTML = ''
}

function followOther(e) {
    console.log(e.keyCode)
    if (e.keyCode != 13) return;
    let username = document.querySelector('#follow-user-input').value;

    api.followUser(username, checkStore('AUTH_KEY'), doNothing, doNothing).then(resp => {
        //resp.json()
        if (resp.status == 200) {
            //alert('Successfully followed '+username);
            document.getElementById('follow-error').innerHTML = 'Successfully followed ' + username;
            setTimeout(clearFollowError, 5000)
        } else {
            showError(resp)
        }
    });

}

async function showError(resp,isUserProfile) {
    let respJson = await resp.json();
    // alert(respJson['message'])
    if (isUserProfile){
        alert('Fail to follow. please try again later');
    }
    document.getElementById('follow-error').innerHTML = respJson['message'];
    setTimeout(clearFollowError, 5000)
}

function unfollowOther(e) {
    e = e || window.event;
    let target = e.target || e.srcElement;
    let username = target.getAttribute('arg');
    let userId = target.getAttribute('arg2')
    api.unFollowUser(username, checkStore('AUTH_KEY'), doNothing, doNothing).then(resp => {
        //resp.json()
        if (resp.status == 200) {
            alert('Successfully ufollowed '+username);
            removeNode('line-'+username)

            let title = document.querySelector('#followingNum').getAttribute('title').split(',');
            let index = title.indexOf(userId);
            title.splice(index, 1);
            document.querySelector('#followingNum').setAttribute('title', title.toString());
            setAttr('#number-of-following','title',title.toString() )
            let num = getContent('#number-of-following');
            setContent('#number-of-following', parseInt(num)-1);

        } else {
            showError(resp,true)
        }
    });
}


//---------- routing -----------
function Routing() {
    this.url = '';
    this.segment = {};
    this.goTo = function(path, func) {
        this.segment[path] = func || function () {};
    };

    this.reload = function() {
        let equalIndex = location.hash.indexOf('=')
        let arg;
        if(equalIndex>=0){
            this.url = location.hash.slice(1,equalIndex) || '/';
            arg = location.hash.slice(equalIndex+1);
        } else
            this.url = location.hash.slice(1) || '/';
        if(this.segment[this.url]){
            if(arg){
                let e = {
                    target: {
                        arg: arg,
                        getAttribute: (a,b) =>arg
                    }
                }
                this.segment[this.url](e);

            }else
                this.segment[this.url]();
        }
    };
    this.start = function () {
        window.addEventListener('load',this.reload.bind(this),false);
        window.addEventListener('hashchange',this.reload.bind(this),false)
    }
}
var route = new Routing();
route.start();

route.goTo('/', logout)
route.goTo('/feed', gotoFeed)
route.goTo('/profile', showUserProfile);
