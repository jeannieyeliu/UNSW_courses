/* returns an empty array of size max */
export const range = (max) => Array(max).fill(null);

/* returns a randomInteger */
export const randomInteger = (max = 1) => Math.floor(Math.random()*max);

/* returns a randomHexString */
const randomHex = () => randomInteger(256).toString(16);

/* returns a randomColor */
export const randomColor = () => '#'+range(3).map(randomHex).join('');

/**
 * You don't have to use this but it may or may not simplify element creation
 * 
 * @param {string}  tag     The HTML element desired
 * @param {any}     data    Any textContent, data associated with the element
 * @param {object}  options Any further HTML attributes specified
 */
export function createElement(tag, data, options = {}) {
    const el = document.createElement(tag);
    el.textContent = data;
   
    // Sets the attributes in the options object to the element
    return Object.entries(options).reduce(
        (element, [field, value]) => {
            element.setAttribute(field, value);
            return element;
        }, el);
}

/**
 * Given a post, return a tile with the relevant data
 * @param   {object}        post 
 * @returns {HTMLElement}
 */
export function createPostTile(post) {
    const section = createElement('section', null, { class: 'post' });

    section.appendChild(createElement('h2', post.meta.author, { class: 'post-title' }));

    section.appendChild(createElement('img', null, 
        { src: '/images/'+post.src, alt: post.meta.description_text, class: 'post-image' }));

    return section;
}

// Given an input element of type=file, grab the data uploaded for use
export function uploadImage(event) {
    const [ file ] = event.target.files;

    const validFileTypes = ['image/jpeg', 'image/png', 'image/jpg'];
    const valid = validFileTypes.find(type => type === file.type);

    // bad data, let's walk away
    if (!valid)
        return false;
    
    // if we get here we have a valid image
    const reader = new FileReader();
    
    reader.onload = (e) => {
        // do something with the data result
        const dataURL = e.target.result;
        const image = createElement('img', null, { src: dataURL });
        document.body.appendChild(image);
    };

    // this returns a base64 image
    reader.readAsDataURL(file);
}

/* 
    Reminder about localStorage
    window.localStorage.setItem('AUTH_KEY', someKey);
    window.localStorage.getItem('AUTH_KEY');
    localStorage.clear()
*/
export function checkStore(key) {
    if (window.localStorage)
        return window.localStorage.getItem(key);
    else
        return null

}

export function setLocalStorageItem(key, content) {
    if (window.localStorage)
        window.localStorage.setItem(key,content)
}

export function removeLocalStorageItem(key) {
    if (window.localStorage)
        window.localStorage.removeItem(key)
}

/*
    param = {
        'tag': 'div'
        'id': 'aaa';
        listener: {
            'eventName': click,
            'eventFunc': func,
        }
    }
 */
export function newNode(params) {
    let node = document.createElement(params['tag']);
    if (params['class']) {
        node.className = params['class']
    }
    if (params['id']) {
        node.id = params['id'];
    }
    if (params['listener']) {
        node.addEventListener(params['listener']['event'], params['listener']['func'])
    }
    if (params['innerHTML']) {
        node.innerHTML = params['innerHTML']
    }
    if (params['child']) {
        node.appendChild(params['child']);
    }
    if (params['parent']) {
        document.getElementById(params['parent']).appendChild(node);
    }

    if (params['parentNode']){
        params['parentNode'].appendChild(node);
    }
    if (params['childList']){
        for( let i = 0; i < params['childList'].length; i++){
            node.appendChild(params['childList'][i]);
        }
    }
    if (params['title']) {
        node.title = params['title'];
    }

    if (params['arg']){
        node.setAttribute('arg', params['arg']);
    }

    if (params['placeholder']){
        node.setAttribute('placeholder', params['placeholder']);
    }

    if (params['value']){
        node.value = params['value'];
    }

    if (params['type']){
        node.setAttribute('type',params['type'])
    }

    if (params['arg2']) {
        node.setAttribute('arg2', params['arg2']);
    }
    return node;
}

export function addChild(parent, childList) {
    parent = getSingleNode(parent);
    childList = getSingleNode(childList);
    if(childList instanceof Array){
        for(let i = 0; i< childList.length; i++){
            parent.appendChild(childList[i]);
        }
    }else{
        parent.appendChild(childList)
    }
}

export function setContent(node, content) {
    node = getNode(node);
    node.innerHTML = content;
}

export function getContent(node) {
    node = getSingleNode(node);
    return node.innerHTML;
}

export function getAttr(node,attr) {
    node = getNode(node);
    return node.getAttribute(attr)
}

export function setAttr(node,attr, value) {
    node = getNode(node);
    if (node instanceof Array){
        for(let i = 0; i< node.length; i++){
            if(node[i])
                node[i].setAttribute(attr, value)
        }
    } else if (node) {
        node.setAttribute(attr,value)
    }
}

export function removeNode(node) {
    node = getNode(node);
    if(node instanceof Array){
        for(let i = 0; i< node.length; i++){
            if(node[i] && node[i].parentNode)
                node[i].parentNode.removeChild(node[i]);
        }
    } else if (node && node.parentNode) {
        node.parentNode.removeChild(node);
    }
}

export function addListener(node,event, func) {
    node = getNode(node);
    if(node instanceof Array){
        for(let i = 0; i< node.length; i++){
            if(node[i])
                node[i].addEventListener(event,func);
        }
    } else if (node) {
        node.addEventListener(event, func);
    }
}

export function addClass(node, classList){
    node = getNode(node);
    if(node instanceof Array){
        for(let i = 0; i< node.length; i++){
            if (classList instanceof Array) {
                for(let j = 0; j < classList.length; j++){
                    node[i].classList.add(classList[j]);
                }
            }else{
                node[i].classList.add(classList)
            }
        }
    } else if (node) {
        if (classList instanceof Array) {
            for(let j = 0; j < classList.length; j++){
                node.classList.add(classList[j]);
            }
        }else{
            node.classList.add(classList)
        }
    }
}

export function removeClass(node, classList) {
    node = getNode(node);

    if(node instanceof Array){
        for(let i = 0; i< node.length; i++){
            if (classList instanceof Array) {
                for(let j = 0; j < classList.length; j++){
                    node[i].classList.add(classList[j]);
                }
            }else{
                node[i].classList.remove(classList)
            }
        }
    } else if (node) {
        if (classList instanceof Array) {
            for(let j = 0; j < classList.length; j++){
                node.classList.remove(classList[j]);
            }
        }else{
            node.classList.remove(classList)
        }
    }
}

function getNode(node) {
    if (typeof node === "string") {
        return getSingleNode(node)
    }

    if (node instanceof Array){
        for (let i = 0; i < node.length; i++ ){
            node[i] = getSingleNode(node[i]);
        }
    }
    return node;
}

function getSingleNode(node) {
    if (typeof node === "string") {
        node = document.querySelector(node);
    }

    if (!node) {
        node = document.getElementById(node);
    }
    return node;
}

