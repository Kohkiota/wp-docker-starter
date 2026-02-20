import{n as l,o as x}from"./index.bd66e758.js";import"./translations.d159963e.js";import{h as s,i as m}from"./icon.cee978f3.js";import{_ as p}from"./default-i18n.20001971.js";import"./runtime-dom.esm-bundler.5d5e6b71.js";import"./helpers.bf0d86e6.js";import"./AiContent.a028a71a.js";import"./_plugin-vue_export-helper.eefbdd86.js";const{addFilter:h}=window.wp.hooks,{BlockControls:b}=window.wp.blockEditor,{Button:u,ToolbarGroup:$,ToolbarButton:k}=window.wp.components,{Fragment:I,render:y,unmountComponentAtNode:_}=window.wp.element,{createHigherOrderComponent:B}=window.wp.compose,{select:d,useSelect:A}=window.wp.data,S="all-in-one-seo-pack",g={generateWithAI:p("Generate with AI",S),editWithAI:p("Edit with AI",S)};let w=!1;const f=(i,o={})=>{window.aioseoBus.$emit("do-post-settings-main-tab-change",{name:"aiContent"}),i.classList.add("is-busy"),i.disabled=!0;const e=x(),t=l();setTimeout(()=>{t.initiator=o==null?void 0:o.initiator,(!t.initiator||!t.initiator.slug)&&t.resetInitiator(),e.isModalOpened="image-generator",i.classList.remove("is-busy"),i.disabled=!1},500)},z=()=>{l().extend.imageBlockToolbar&&(w||(h("editor.BlockEdit","aioseo/extend-image-block-toolbar",B(o=>e=>{if(e.name!=="core/image"||!e.attributes.url)return s`<${o} ...${e} />`;const t=A(n=>n("core").getMedia(e.attributes.id)||null,[`media-${e.attributes.id}`]);return s`
				<${I}>
					<${b}>
						<${$}>
							<${k}
								icon=${m}
								iconSize=${24}
								label=${g.editWithAI}
								onClick=${n=>{f(n.currentTarget,{initiator:{slug:"image-block-toolbar",wpMedia:t}})}}
								style=${{maxHeight:"90%",alignSelf:"center",padding:"0"}}
							/>
						</${$}>
					</${b}>

					<${o} ...${e} />
				</${I}>`},"extendImageBlockToolbar")),w=!0))},W=()=>{var a,c;if(!l().extend.imageBlockPlaceholder)return;const o=d("core/block-editor").getSelectedBlock();if(!o||o.name!=="core/image"||(a=o.attributes)!=null&&a.url)return;const e=document.getElementById(`block-${o.clientId}`),t=e==null?void 0:e.querySelector(".components-form-file-upload");if(!t||e!=null&&e.querySelector(".aioseo-ai-image-generator-btn"))return;const n=document.createElement("div");y(s`
			<${u}
				className=${"aioseo-ai-image-generator-btn"}
				variant=${"secondary"}
				icon=${m}
				iconSize=${"20"}
				__next40pxDefaultSize=${!0}
			>
				${g.generateWithAI}
			</${u}>`,n);const r=(c=n.firstChild)==null?void 0:c.cloneNode(!0);r&&(t.after(r),r.addEventListener("click",()=>{f(r,{initiator:{slug:"image-block-placeholder"}})})),_(n),n.remove()},P=()=>{var e;if(!l().extend.featuredImageButton||d("core/edit-post").getActiveGeneralSidebarName()!=="edit-post/document")return;if(d("core/editor").getEditedPostAttribute("featured_media")){(e=document.querySelector(".aioseo-ai-image-generator-btn-featured-image"))==null||e.remove();return}setTimeout(()=>{var c;const t=document.querySelector(".editor-post-featured-image__container"),n=t==null?void 0:t.querySelector("button");if(!n||t!=null&&t.querySelector(".aioseo-ai-image-generator-btn-featured-image"))return;t.style.display="flex",t.style.gap="8px";const r=document.createElement("div");y(s`
				<${u}
					className=${"aioseo-ai-image-generator-btn-featured-image"}
					variant=${"secondary"}
					icon=${m}
					iconSize=${"20"}
					__next40pxDefaultSize=${!0}
					title=${g.generateWithAI}
				/>`,r);const a=(c=r.firstChild)==null?void 0:c.cloneNode(!0);a&&(n.after(a),a.addEventListener("click",()=>{f(a,{initiator:{slug:"featured-image-btn"}})})),_(r),r.remove()})};export{P as extendFeaturedImageButton,W as extendImageBlockPlaceholder,z as extendImageBlockToolbar};
