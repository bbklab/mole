<head>
	<meta charset="UTF-8">
</head>
<body style="font-size:14px;color:#2E2E2E;font-family:'\5FAE\8F6F\96C5\9ED1'">
	<div style="width:1000px;margin:0 auto;border:2px dashed #9FC5F8;border-radius:4px;padding:30px 0 0 40px;">
			<div style="height:47px;padding-bottom:49px;">
				<a href="http://esop.eyou.net">
					<img src="http://esop.eyou.net/images/logo.png" style="float:left;"/>
				</a>
				<a style="height:24px;width:35px;text-decoration:none;border-radius:4px;backgroUnd:#FCB322;text-align:center;color:#FFF;font-size:10px;float:right;margin-right:50px;line-height:24px;margin-top:14px;">${MOLE-NOTIFY-MAIL_LEVEL}</a>
			</div>
			<br clear="both"/>
			<div style="width:960px;">
				<p style="width:49%;float:left;padding:0;margin:10px 0;">
					<span style="width:100px;display:inline-block;color:#797979;">插件名称</span>
					<i style="font-style:normal">：${MOLE-NOTIFY-MAIL_PLUGIN}</i>
				</p>
				<p style="width:49%;float:left;padding:0;margin:10px 0;">
					<span style="width:100px;display:inline-block;color:#797979;">检测时间</span>
					<i style="font-style:normal">：${MOLE-NOTIFY-MAIL_TIME}</i>
				</p>
				<p style="width:49%;float:left;padding:0;margin:10px 0;">
					<span style="width:100px;display:inline-block;color:#797979;">标题</span>
					<i style="font-style:normal">：${MOLE-NOTIFY-MAIL_TITLE}</i>
				</p>
				<p style="width:49%;float:left;padding:0;margin:10px 0;">
					<span style="width:100px;display:inline-block;color:#797979;">概要</span>
					<i style="font-style:normal">：${MOLE-NOTIFY-MAIL_SUMMARY}</i>
				</p>
				<p style="width:100%;float:left;margin-bottom:0;padding:0;margin:10px 0;">
					<span style="width:100px;display:inline-block;color:#797979;">详细描述：</span>				
				</p>
				<p style="width:100%;float:left;padding:0;margin:10px 0;">
					<span style="display:inline-block;"></span>
					<i style="font-style:normal;display:inline-block;background:#F7F7F7;line-height:30px;padding:10px;">
					${MOLE-NOTIFY-MAIL_DETAILS}
</i>
				</p>
				<p style="width:49%;float:left;padding:0;margin:10px 0;">
					<span style="width:100px;display:inline-block;color:#797979;">自动处理：</span><br><br>
					<i style="font-style:normal">${MOLE-NOTIFY-MAIL_AUTOHANDLE}</i>
				</p>

				
			</div>
			<br clear="both"/>
			<p style="height:1px;width:960px;background:#EAEAEA;overflow:hidden;line-height:1px;"></p>
			<p style="color:#797979;">该邮件为智能运维平台系统邮件，请勿直接回复！</p>
	</div>
</body>
