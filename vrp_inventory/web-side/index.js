$(document).ready(function(){
	window.addEventListener("message",function(event){
		switch(event.data.action){
			case "showMenu":
				updateMochila();
				$("#actionmenu").fadeIn(500);
			break;

			case "hideMenu":
				$("#actionmenu").fadeOut(500);
			break;

			case "updateMochila":
				updateMochila();
			break;
		}
	});

	document.onkeyup = function(data){
		if (data.which == 27){
			$.post("http://vrp_inventory/invClose");
		}
	};
});

const updateDrag = () => {
	$('.item').draggable({
		helper: 'clone',
		appendTo: 'body',
		zIndex: 99999,
		revert: 'invalid',
		opacity: 0.5,
		start: function(event,ui){
			$(this).children().children('img').hide();
			itemData = { key: $(this).data('item-key'), type: $(this).data('item-type') };

			if (itemData.key === undefined || itemData.type === undefined) return;

			let $el = $(this);
			$el.addClass("active");
		},
		stop: function(){
			$(this).children().children('img').show();

			let $el = $(this);
			$el.removeClass("active");
		}
	})

	$('.use').droppable({
		hoverClass: 'hoverControl',
		drop: function(event,ui){
			itemData = { key: ui.draggable.data('item-key'), type: ui.draggable.data('item-type') };

			if (itemData.key === undefined || itemData.type === undefined) return;

			$.post("http://vrp_inventory/useItem", JSON.stringify({
				item: itemData.key,
				type: itemData.type,
				amount: Number($("#amount").val())
			}))

			document.getElementById("amount").value = "";
		}
	})

	$('.drop').droppable({
		hoverClass: 'hoverControl',
		drop: function(event,ui){
			itemData = { key: ui.draggable.data('item-key') };

			if (itemData.key === undefined) return;

			$.post("http://vrp_inventory/dropItem", JSON.stringify({
				item: itemData.key,
				amount: Number($("#amount").val())
			}))

			document.getElementById("amount").value = "";
		}
	})

	$('.send').droppable({
		hoverClass: 'hoverControl',
		drop: function(event,ui){
			itemData = { key: ui.draggable.data('item-key') };

			if (itemData.key === undefined) return;

			$.post("http://vrp_inventory/sendItem", JSON.stringify({
				item: itemData.key,
				amount: Number($("#amount").val())
			}))

			document.getElementById("amount").value = "";
		}
	})
}

const formatarNumero = (n) => {
	var n = n.toString();
	var r = '';
	var x = 0;

	for (var i = n.length; i > 0; i--) {
		r += n.substr(i - 1, 1) + (x == 2 && i != 1 ? '.' : '');
		x = x == 2 ? 0 : x + 1;
	}

	return r.split('').reverse().join('');
}

const updateMochila = () => {
	document.getElementById("amount").value = "";
	$.post("http://vrp_inventory/requestMochila",JSON.stringify({}),(data) => {
		const nameList = data.inventario.sort((a,b) => (a.name > b.name) ? 1: -1);
		$('#invleft').html(`
			<div class="peso"><b>OCUPADO:</b>  ${(data.peso).toFixed(2)} <c>kg</c>    <s>|</s>   <b>LIVRE:</b>  ${(data.maxpeso-data.peso).toFixed(2)} <c>kg</c>   <s>|</s>    <b>TAMANHO:</b>  ${(data.maxpeso).toFixed(2)} <c>kg</c></div>
			${nameList.map((item) => (`
				<div class="item" style="background-image: url('images/${item.index}.png'); background-size: 100px 100px;" data-item-key="${item.key}" data-item-type="${item.type}" data-name-key="${item.name}">
					<div id="peso">${(item.peso*item.amount).toFixed(2)} <c>kg</c> | ${formatarNumero(item.amount)}</div>
					<div id="itemname">${item.name}</div>
				</div>
			`)).join('')}
		`);
		updateDrag();
	});
}