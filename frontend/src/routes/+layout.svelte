<!-- src/routes/+layout.svelte -->
<script lang="ts">
	import '../app.css';
	import { onMount } from 'svelte';
	import { initWeb3 } from './init';

	import { browser } from '$app/environment';
	
	let { children } = $props();
	
	onMount(async () => {
		if (browser) {
			await initWeb3();
		}
	})
  </script>
  

	{@render children()}
  