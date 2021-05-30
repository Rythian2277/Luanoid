// https://github.com/1ForeverHD/ZonePlus/tree/main/docs/javascripts

const style = `.tag {
	color: #ffffff;
	line-height: .55rem;
	padding: 4px;
	margin-left: 7px !important;
	margin: 0 !important; 
	background-clip: padding-box;
	border-radius: 2px;
	display: inline-block;
	font-size: .6rem;
	font-family: "Roboto";
	font-weight: normal;
}
.read-only {
	background-color: rgb(80, 180, 80);
}
.client-only {
	background-color: rgb(40, 80, 220);
}
.server-only {
	background-color: rgb(240, 200, 80);
}
.not-replicated {
	background-color: rgb(240, 80, 80);
}.internal {
	background-color: rgb(240, 160, 80);
}
h4 {
	display: inline;
}`

var inner = document.body.innerHTML
inner = inner.replace(/{read-only}/g, '<p class="tag read-only">read-only</p>');
inner = inner.replace(/{server-only}/g, '<p class="tag server-only">server-only</p>');
inner = inner.replace(/{client-only}/g, '<p class="tag client-only">client-only</p>');
inner = inner.replace(/{not-replicated}/g, '<p class="tag not-replicated">not-replicated</p>');
inner = inner.replace(/{internal}/g, '<p class="tag internal">internal</p>');
document.body.innerHTML = inner

const styleElement = document.createElement("style")
styleElement.innerHTML = style

document.head.appendChild(styleElement)

function cleaner(el) {
	if (el.innerHTML === '&nbsp;' || el.innerHTML === '') {
		el.parentNode.removeChild(el);
	}
}

const elements = document.querySelectorAll('p');
elements.forEach(cleaner);