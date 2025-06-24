<!-- src/routes/+layout.svelte -->
<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { initWeb3 } from './init';
	import Header from './header.svelte';

	import { browser } from '$app/environment';
	
	let { children } = $props();
	
	onMount(async () => {
		if (browser) {
			await initWeb3();
		}
	})
  </script>
  
  <div class="drawer">
	<input id="my-drawer" type="checkbox" class="drawer-toggle" />
	<div class="drawer-content flex flex-col min-h-full">
		<div class="flex-grow">
			<Header />
			{@render children()}
		</div>
	</div>

	<div class="drawer-side">
		<label for="my-drawer" aria-label="close sidebar" class="drawer-overlay"></label>
		<ul class="menu bg-base-200 text-base-content min-h-full w-80 px-4 pt-20">
		  <!-- Sidebar content here -->
		  <li><a>How it Works</a></li>
		  <li><a>Prizes</a></li>
		  <li><a>FAQ</a></li>
		</ul>
	  </div>
</div>